# frozen_string_literal: true

# Provisioning helpers for the staging dashboard, layered on top of
# `DashboardConsole`. Each method drops into a Rails-equivalent context
# on the deployed staging app and uses AR / service objects directly,
# which is faster + more deterministic than driving the dashboard's
# HTTP surface via Capybara and dodges the session-auth dance.
#
# The trade-off: these helpers exercise model + service code, not
# controller code. If a spec needs to assert the controller-level UX
# (e.g., the wizard flow, the course-show page), drive the dashboard
# via Capybara separately. These helpers exist to set up state, not to
# test the dashboard's web surface.
module DashboardAdminClient
  module_function

  # Provisions a Wiki Education course on the staging dashboard with
  # the given attributes + a default instructor. Returns the Course's
  # slug and id for downstream use. The instructor user is assumed
  # to already exist on staging (`User.find_by(username: instructor_username)`).
  def create_course(title:, school:, term:, instructor_username:, start_date: nil, end_date: nil)
    start_date ||= Date.today
    end_date   ||= Date.today + 90

    script = <<~RUBY
      require 'json'
      instructor = User.find_by!(username: #{instructor_username.inspect})
      slug = "#{school.tr(' ', '_')}/#{title.tr(' ', '_')}_(#{term.tr(' ', '_')})"
      home_wiki = Wiki.find_or_create_by(language: 'en', project: 'wikipedia')
      course = Course.find_or_initialize_by(slug: slug)
      course.assign_attributes(
        title: #{title.inspect},
        school: #{school.inspect},
        term: #{term.inspect},
        start: Date.parse(#{start_date.to_s.inspect}),
        end: Date.parse(#{end_date.to_s.inspect}),
        type: 'ClassroomProgramCourse',
        home_wiki: home_wiki,
        passcode: SecureRandom.urlsafe_base64(8),
        timeline_start: Date.parse(#{start_date.to_s.inspect}),
        timeline_end: Date.parse(#{end_date.to_s.inspect})
      )
      course.save!
      CoursesUsers.find_or_create_by!(
        user: instructor, course: course,
        role: CoursesUsers::Roles::INSTRUCTOR_ROLE
      )
      puts({ id: course.id, slug: course.slug }.to_json)
    RUBY
    DashboardConsole.run_json(script)
  end

  # Approves a course by linking it to a campaign — that's what makes
  # `Course#approved?` return true. Pass the campaign's slug (e.g.,
  # 'wikipedia_student_program' or whatever the staging dashboard has).
  def approve_course(slug:, campaign_slug:)
    script = <<~RUBY
      course = Course.find_by!(slug: #{slug.inspect})
      campaign = Campaign.find_by!(slug: #{campaign_slug.inspect})
      course.campaigns << campaign unless course.campaigns.include?(campaign)
      puts course.approved?
    RUBY
    DashboardConsole.run(script).strip == 'true'
  end

  def delete_course(slug:)
    script = <<~RUBY
      course = Course.find_by(slug: #{slug.inspect})
      course&.destroy
      puts 'ok'
    RUBY
    DashboardConsole.run(script).strip == 'ok'
  end

  # Delete every LtiCourseBinding stamped with this LMS context title,
  # along with its dependent contexts + line items. Deleting the dashboard
  # Course does NOT cascade to its binding (Course has no association to
  # it), so a spec that binds a course must also clear the binding to stay
  # hermetic. Keyed on lms_context_title — the launch idtoken stamps the
  # Canvas course title onto the binding, and the staging specs use a
  # unique per-run Canvas course name, so this targets exactly the run's
  # binding(s) without needing the course to still exist.
  def delete_bindings_for(context_title:)
    script = <<~RUBY
      LtiCourseBinding.where(lms_context_title: #{context_title.inspect}).destroy_all
      puts 'ok'
    RUBY
    DashboardConsole.run(script).strip == 'ok'
  end

  # Drop a course's campaign links so `Course#approved?` (campaigns.any? &&
  # !withdrawn) flips back to false. Lets a screenshot spec bind an
  # approved course (only approved courses appear in the setup dropdown)
  # and then re-create the "awaiting approval" state a student hits.
  def unapprove_course(slug:)
    script = <<~RUBY
      course = Course.find_by!(slug: #{slug.inspect})
      course.campaigns.clear
      puts course.approved?
    RUBY
    DashboardConsole.run(script).strip == 'false'
  end

  # Seed the Canvas gradebook with every column the deep-link picker offers for
  # this course — the account indicator, the trainings roll-up, and one per
  # exercise block — by creating each AGS line item tagged with its gradable's
  # resource marker. That is exactly what Canvas ends up with after an instructor
  # runs the Modules "Import Wikipedia assignments" flow, so SyncLtiLineItems'
  # discovery binds them the same way; it just skips the browser round-trip so a
  # gallery run is deterministic.
  #
  # Replaces an older shortcut that forced the binding into a 'standard'
  # gradebook_granularity to make the Dashboard auto-create the columns. That
  # layout no longer exists — deep-link-first is the only one — so these
  # galleries now exercise the shipped path.
  def import_all_columns(course_slug:)
    script = <<~RUBY
      course = Course.find_by!(slug: #{course_slug.inspect})
      binding = LtiCourseBinding.find_by!(course_id: course.id)
      svc = LtiServiceSession.new(binding)
      launch_url = "https://\#{ENV['LTIAAS_DOMAIN']}/lti/launch"
      DeepLinkableGradables.new(course).result.each do |gradable|
        svc.upsert_line_item(label: gradable.label, tag: gradable.resource,
                             launch_url: launch_url)
      end
      puts 'ok'
    RUBY
    DashboardConsole.run(script).strip == 'ok'
  end

  def find_binding(course_slug:)
    script = <<~RUBY
      require 'json'
      course = Course.find_by(slug: #{course_slug.inspect})
      binding = course && LtiCourseBinding.find_by(course_id: course.id)
      puts((binding ? binding.attributes.slice('id', 'course_id',
                                               'lms_context_id') : nil).to_json)
    RUBY
    DashboardConsole.run_json(script)
  end

  # Run one binding's NRPS roster sync inline (the worker's body, not the
  # async enqueue) so the spec gets a deterministic result instead of
  # racing Sidekiq. Returns the binding's resulting roster-sync timestamp.
  def run_roster_sync(binding_id:)
    script = <<~RUBY
      LtiRosterSyncWorker.new.perform(#{binding_id})
      puts LtiCourseBinding.find(#{binding_id}).last_roster_sync_at.to_s
    RUBY
    DashboardConsole.run(script).strip
  end

  # Run one binding's AGS line-item sync inline (SyncLtiLineItems via its
  # worker) so the local line items exist deterministically instead of
  # racing the async enqueue that binding kicks off. Returns the resulting
  # count of active local line items for the binding.
  def run_line_item_sync(binding_id:)
    script = <<~RUBY
      LtiLineItemSyncWorker.new.perform(#{binding_id})
      puts LtiLineItem.active.where(lti_course_binding_id: #{binding_id}).count
    RUBY
    DashboardConsole.run(script).strip
  end

  # Run one binding's AGS grade sync inline. Returns the binding's
  # resulting grade-sync timestamp (or the error column if it failed).
  def run_grade_sync(binding_id:)
    script = <<~RUBY
      LtiGradeSyncWorker.new.perform(#{binding_id})
      b = LtiCourseBinding.find(#{binding_id})
      puts(b.last_grade_sync_error.presence || b.last_grade_sync_at.to_s)
    RUBY
    DashboardConsole.run(script).strip
  end

  # All LtiContext rows for the binding bound to this course, as an array
  # of plain hashes — enough for the spec to assert who got discovered
  # and whether they're linked.
  def list_contexts(course_slug:)
    script = <<~RUBY
      require 'json'
      course = Course.find_by(slug: #{course_slug.inspect})
      binding = course && LtiCourseBinding.find_by(course_id: course.id)
      rows = binding ? binding.lti_contexts.map { |c|
        c.attributes.slice('id', 'user_id', 'user_lti_id', 'name', 'email')
         .merge('roles' => Array(c.roles))
      } : []
      puts rows.to_json
    RUBY
    DashboardConsole.run_json(script)
  end

  # The roles a given dashboard user holds on a course (empty array if
  # not enrolled). Used to assert a student got JoinCourse'd as STUDENT.
  def course_roles_for(course_slug:, username:)
    script = <<~RUBY
      require 'json'
      course = Course.find_by(slug: #{course_slug.inspect})
      user = User.find_by(username: #{username.inspect})
      roles = (course && user) ? CoursesUsers.where(course_id: course.id,
                                                    user_id: user.id).pluck(:role) : []
      puts roles.to_json
    RUBY
    DashboardConsole.run_json(script)
  end

  # Build a minimal, deterministic timeline on the course: one block with
  # a single training-kind module and one block with a single exercise
  # module that has a sandbox_location. Picked dynamically from the
  # staging training library so we don't hard-code ids. Returns the chosen
  # module metadata plus the line-item labels SyncLtiLineItems will derive
  # (so the spec knows which Canvas assignment to read back). Raises (→
  # the caller skips) if the library lacks a usable module of either kind.
  # Build the course's timeline by running the **real course wizard**, rather than
  # hand-assembling a couple of blocks. This is what makes the galleries a faithful
  # picture of a typical course: the researchwrite wizard is what an instructor
  # actually runs, and its output is the default assignment set students meet.
  #
  # Measured against a hand-built timeline, for the record:
  #
  #                        hand-built   wizard
  #   weeks                         1       12
  #   blocks                        2       29
  #   assigned module refs          1       28
  #   deep-linkable gradables       3        9
  #
  # The `logic` set below is the canonical walk through the wizard's 16 panels —
  # graded training, LLM training, the recommended early-editing tasks, sandboxes,
  # individual work, an instructor-prepared article list, medical topics, one
  # handout, two peer reviewers, all three discussions, and the presentation /
  # reflective-essay / extra-credit supplements. It mirrors
  # `go_through_researchwrite_wizard` in spec/features/course_creation_spec.rb,
  # whose `expected_course_blocks` is 29 — so the assertion below is a live check
  # that this set still tracks `config/wizard/researchwrite/content.yml`. If
  # content.yml changes, this and that feature spec notice together.
  WIZARD_LOGIC = %w[
    graded_training llm_training
    critique add_to_article fact_verification
    improving_representation yes_sandboxes working_individually
    choose_articles_from_list medical_topics art_history_handout
    2_peer_reviewers
    content_gaps_discussion sources_and_plagiarism_discussion
    thinking_about_wikipedia_discussion
    additional_article_extra_credit presentation reflective_essay
  ].freeze

  EXPECTED_WIZARD_BLOCKS = 29

  # Returns a superset of what build_timeline returned, so existing callers keep
  # working: a representative training module and exercise (the first exercise with
  # a sandbox_location, which is what the sandbox-preview shots need), plus every
  # deep-linkable gradable so a gallery can import the whole column set.
  # `subject_exercise_path` picks which of the timeline's exercises the caller
  # treats as its subject — the one whose label and module the payload's
  # `exercise_*` fields describe. Default is the first exercise with a
  # sandbox_location, which is what the sandbox-preview shots need; the
  # fact-verification gallery passes 'verify_claim' to get the one exercise that
  # runs entirely in the Dashboard.
  def build_timeline(course_slug:, wizard_id: 'researchwrite', subject_exercise_path: nil)
    script = <<~RUBY
      require 'json'
      require_dependency "\#{Rails.root}/lib/wizard_timeline_manager"
      course = Course.find_by!(slug: #{course_slug.inspect})
      WizardTimelineManager.update_timeline_and_tags(
        course, #{wizard_id.inspect},
        { 'wizard_output' => { 'output' => ['essentials'],
                               'logic' => #{WIZARD_LOGIC.inspect}, 'tags' => [] } }
      )
      course.reload
      blocks = course.blocks.to_a
      raise "expected #{EXPECTED_WIZARD_BLOCKS} blocks, got \#{blocks.size} — the wizard " \\
            'content or the logic set has changed' unless blocks.size == #{EXPECTED_WIZARD_BLOCKS}

      gradables = DeepLinkableGradables.new(course).result
      exercise_blocks = gradables.select { |g| g.gradable_type == 'Block' }
      wanted_path = #{subject_exercise_path.inspect}
      subject = exercise_blocks.find do |g|
        mod = Block.find(g.gradable_id).training_modules.find(&:exercise?)
        wanted_path ? mod&.exercise_path == wanted_path : mod&.sandbox_location.present?
      end
      raise "no exercise block matching \#{wanted_path || 'a sandbox_location'} in the " \
            'wizard timeline' unless subject

      subject_module = Block.find(subject.gradable_id).training_modules.find(&:exercise?)
      training = blocks.flat_map(&:training_modules).reject(&:exercise?).first
      puts({
        weeks: course.weeks.count,
        blocks: blocks.size,
        training_module_id: training&.id,
        training_module_name: training&.name,
        exercise_block_id: subject.gradable_id,
        exercise_module_id: subject_module.id,
        exercise_module_name: subject_module.name,
        exercise_sandbox_location: subject_module.sandbox_location,
        training_line_item_label: DeepLinkableGradables::TRAININGS_LABEL,
        exercise_line_item_label: subject.label,
        gradables: gradables.map { |g| { resource: g.resource, label: g.label,
                                        type: g.gradable_type, id: g.gradable_id } },
        # One entry per exercise block, which is what the gradebook galleries walk
        # to mark mixed progress. This shape is what the old hand-built
        # full-timeline builder returned, so its callers needed no changes.
        blocks: exercise_blocks.map { |g|
          mod = Block.find(g.gradable_id).training_modules.find(&:exercise?)
          { block_id: g.gradable_id, label: g.label, module_id: mod&.id,
            sandbox: mod&.sandbox_location }
        }
      }.to_json)
    RUBY
    DashboardConsole.run_json(script)
  end


  # Point the student's "current claim" cursor (VerificationClaimAssignment) at a
  # pooled claim the course would be served, so the fact-verification drill-down
  # reads "In progress" (taken, not yet submitted). Returns the claim's article
  # title, or 'no_claim' when the serving pool is empty.
  def take_verification_claim(course_slug:, username:)
    script = <<~RUBY
      course = Course.find_by!(slug: #{course_slug.inspect})
      user = User.find_by!(username: #{username.inspect})
      tile = RelevantClaimRevisionsForCourse.new(course).tiles.first
      if tile.nil?
        puts 'no_claim'
      else
        claim = VerificationClaim.where(article_id: tile.article.id, mw_rev_id: tile.mw_rev_id).first
        assignment = VerificationClaimAssignment.find_or_initialize_by(user: user, course: course)
        assignment.verification_claim = claim
        assignment.save!
        puts claim.article_title.to_s
      end
    RUBY
    DashboardConsole.run(script).strip
  end

  # Build a realistic multi-week timeline — the standard article-writing
  # milestones, one exercise per week, plus one training block on week 1 (so the
  # trainings-rollup column exists). Picked by slug from the staging library.
  # Returns the training module id and one entry per exercise block
  # ({ block_id, label, module_id, sandbox }) in timeline order, so the gallery
  # spec can build its columns, drill into the sandbox ones, and mark progress.

  # Fast path for the full-course gallery: create a Canvas gradebook column per
  # given exercise block via AGS (tagged `Block:<id>`), standing in for the
  # instructor deep-linking each. SyncLtiLineItems' discovery then binds them.
  # `blocks` is build_timeline's exercise-block entries to columnize. Returns 'ok'.
  def upsert_exercise_columns(binding_id:, blocks:)
    items = blocks.map { |b| { 'id' => b['block_id'], 'label' => b['label'] } }
    script = <<~RUBY
      require 'json'
      b = LtiCourseBinding.find(#{binding_id})
      svc = LtiServiceSession.new(b)
      JSON.parse(#{items.to_json.inspect}).each do |item|
        svc.upsert_line_item(label: item['label'], tag: "Block:\#{item['id']}")
      end
      puts 'ok'
    RUBY
    DashboardConsole.run(script).strip
  end

  # Fabricate linked LtiContexts for a set of Wikipedia usernames on the course's
  # bound binding, so the instructor roster shows a realistic multi-student class
  # without driving N browser logins (the way real launches would populate it).
  # Creates the Dashboard user when missing. Returns the usernames that linked.
  # Editing and reviewing article assignments for the gallery roster. Without them
  # the article panel and the peer-review column have nothing to report — they'd
  # read "No article chosen yet" and "None assigned yet", which is one worthwhile
  # shot, not the state every shot should be in.
  #
  # `editing` / `reviewing` are { username => article title }.
  def assign_articles(course_slug:, editing: {}, reviewing: {})
    script = <<~RUBY
      course = Course.find_by!(slug: #{course_slug.inspect})
      wiki = course.home_wiki
      { assigned: #{editing.inspect}, reviewing: #{reviewing.inspect} }.each do |kind, pairs|
        role = kind == :assigned ? Assignment::Roles::ASSIGNED_ROLE
                                 : Assignment::Roles::REVIEWING_ROLE
        pairs.each do |username, title|
          user = User.find_by(username:)
          next if user.nil?

          Assignment.find_or_create_by!(course:, user:, wiki:, role:, article_title: title)
        end
      end
      puts Assignment.where(course:).count
    RUBY
    DashboardConsole.run(script).strip.to_i
  end

  def link_students(course_slug:, usernames:)
    script = <<~'RUBY'.gsub('__SLUG__', course_slug).gsub('__USERNAMES__', usernames.to_json)
      require 'json'
      course = Course.find_by!(slug: '__SLUG__')
      binding = LtiCourseBinding.find_by!(course_id: course.id)
      linked = []
      JSON.parse('__USERNAMES__').each_with_index do |username, i|
        user = User.find_or_create_by(username: username)
        next unless user.persisted?

        ctx = LtiContext.find_or_initialize_by(lti_course_binding_id: binding.id,
                                               user_lti_id: "gallery-#{i}")
        ctx.user = user
        ctx.lms_id = binding.lms_id
        ctx.roles = ['http://purl.imsglobal.org/vocab/lis/v2/membership#Learner']
        ctx.linked_at = Time.current
        ctx.save!
        linked << username
      end
      puts linked.to_json
    RUBY
    DashboardConsole.run_json(script)
  end

  # Promote the NRPS-discovered (but Wikipedia-unlinked) student context to
  # a fully linked one, the way a real student launch would: point its
  # user_id at the dashboard User for the given Wikipedia username and
  # ensure a STUDENT CoursesUsers row exists. Lets g8/g9 exercise the
  # grade-push path without driving a second browser persona (g7 owns the
  # real-linking assertion). Returns the linked dashboard user_id, or
  # 'no_user' when that account doesn't exist on staging yet.
  def link_student_context(course_slug:, username:)
    script = <<~RUBY
      course = Course.find_by!(slug: #{course_slug.inspect})
      binding = LtiCourseBinding.find_by!(course_id: course.id)
      user = User.find_by(username: #{username.inspect})
      if user.nil?
        puts 'no_user'
      else
        # Roster sync may already have auto-linked the user (email match on a
        # non-anonymized install); promoting is only needed when it hasn't.
        unless binding.lti_contexts.exists?(user_id: user.id)
          context = binding.lti_contexts.where(user_id: nil).order(:id).first
          raise 'no unlinked context to promote' unless context
          context.update!(user_id: user.id, linked_at: Time.current)
        end
        CoursesUsers.find_or_create_by!(user_id: user.id, course_id: course.id,
                                        role: CoursesUsers::Roles::STUDENT_ROLE)
        puts user.id
      end
    RUBY
    DashboardConsole.run(script).strip
  end

  # Undo a student's enrollment + context link on a bound course, so a
  # subsequent launch exercises the join flow again (e.g. the
  # awaiting-approval state, which roster-sync auto-enrollment would
  # otherwise skip past on a name-sharing install).
  def unenroll_student(course_slug:, username:)
    script = <<~RUBY
      course = Course.find_by!(slug: #{course_slug.inspect})
      user = User.find_by!(username: #{username.inspect})
      CoursesUsers.where(course_id: course.id, user_id: user.id).destroy_all
      binding = LtiCourseBinding.find_by(course_id: course.id)
      binding&.lti_contexts&.where(user_id: user.id)
             &.update_all(user_id: nil, linked_at: nil)
      puts 'ok'
    RUBY
    DashboardConsole.run(script).strip == 'ok'
  end

  # Mark a training-kind module complete for the student (sets
  # completed_at), the signal LtiTrainingProgress counts.
  def mark_training_complete(username:, training_module_id:)
    script = <<~RUBY
      user = User.find_by!(username: #{username.inspect})
      tmu = TrainingModulesUsers.find_or_create_by!(
        user_id: user.id, training_module_id: #{training_module_id}
      )
      tmu.update!(completed_at: Time.current)
      puts 'ok'
    RUBY
    DashboardConsole.run(script).strip == 'ok'
  end

  # Mark an exercise-kind module complete for the student in this course's
  # context (sets flags[course_id][:marked_complete]), the signal
  # LtiBlockProgress counts for exercise modules.
  def mark_exercise_complete(course_slug:, username:, exercise_module_id:)
    script = <<~RUBY
      course = Course.find_by!(slug: #{course_slug.inspect})
      user = User.find_by!(username: #{username.inspect})
      tmu = TrainingModulesUsers.find_or_create_by!(
        user_id: user.id, training_module_id: #{exercise_module_id}
      )
      tmu.mark_completion(true, course.id)
      tmu.save!
      puts 'ok'
    RUBY
    DashboardConsole.run(script).strip == 'ok'
  end
end

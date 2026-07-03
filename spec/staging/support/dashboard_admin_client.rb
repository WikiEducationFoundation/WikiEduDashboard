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

  def find_binding(course_slug:)
    script = <<~RUBY
      require 'json'
      course = Course.find_by(slug: #{course_slug.inspect})
      binding = course && LtiCourseBinding.find_by(course_id: course.id)
      puts((binding ? binding.attributes.slice('id', 'course_id', 'lms_context_id',
                                               'gradebook_granularity') : nil).to_json)
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
  def build_timeline(course_slug:, exercise_block_title: 'Evaluate Wikipedia')
    script = <<~RUBY
      require 'json'
      course = Course.find_by!(slug: #{course_slug.inspect})
      training = TrainingModule.all.reject(&:exercise?).first
      exercise = TrainingModule.all.select(&:exercise?).find { |m| m.sandbox_location.present? }
      raise 'no training-kind module available' unless training
      raise 'no exercise module with a sandbox_location available' unless exercise
      week = course.weeks.find_or_create_by!(order: 1) { |w| w.title = 'Week 1' }
      week.blocks.find_or_create_by!(title: 'Trainings') do |b|
        b.kind = Block::KINDS['in_class']
        b.order = 1
        b.training_module_ids = [training.id]
      end
      week.blocks.find_or_create_by!(title: #{exercise_block_title.inspect}) do |b|
        b.kind = Block::KINDS['assignment']
        b.order = 2
        b.training_module_ids = [exercise.id]
      end
      puts({
        training_module_id: training.id,
        training_module_name: training.name,
        exercise_module_id: exercise.id,
        exercise_module_name: exercise.name,
        exercise_sandbox_location: exercise.sandbox_location,
        training_line_item_label: 'Wikipedia trainings',
        exercise_line_item_label: "Wk1 #{exercise_block_title}"
      }.to_json)
    RUBY
    DashboardConsole.run_json(script)
  end

  # Build a realistic multi-week timeline — the standard article-writing
  # milestones, one exercise per week, plus one training block on week 1 (so the
  # trainings-rollup column exists). Picked by slug from the staging library.
  # Returns the training module id and one entry per exercise block
  # ({ block_id, label, module_id, sandbox }) in timeline order, so the gallery
  # spec can build its columns, drill into the sandbox ones, and mark progress.
  def build_full_timeline(course_slug:)
    script = <<~'RUBY'.gsub('__SLUG__', course_slug)
      require 'json'
      course = Course.find_by!(slug: '__SLUG__')
      milestone_slugs = %w[
        evaluate-wikipedia-exercise choose-topic-exercise bibliography-exercise
        outline-exercise continue-improving-exercise copyedit-exercise
        reflective-essay-exercise
      ]
      by_slug = TrainingModule.all.index_by(&:slug)
      training = TrainingModule.all.reject(&:exercise?).first
      blocks = []
      milestone_slugs.each_with_index do |slug, idx|
        mod = by_slug[slug]
        next unless mod

        wk = idx + 1
        week = course.weeks.find_or_create_by!(order: wk) { |w| w.title = "Week #{wk}" }
        if idx.zero? && training
          week.blocks.find_or_create_by!(title: 'Trainings') do |b|
            b.kind = Block::KINDS['in_class']
            b.order = 1
            b.training_module_ids = [training.id]
          end
        end
        block = week.blocks.find_or_create_by!(title: mod.name) do |b|
          b.kind = Block::KINDS['assignment']
          b.order = 2
          b.training_module_ids = [mod.id]
        end
        blocks << { block_id: block.id, label: "Wk#{wk} #{mod.name}",
                    module_id: mod.id, sandbox: mod.sandbox_location }
      end
      puts({ training_module_id: training&.id, blocks: blocks }.to_json)
    RUBY
    DashboardConsole.run_json(script)
  end

  # Fast path for the full-course gallery: create a Canvas gradebook column per
  # given exercise block via AGS (tagged `Block:<id>`), standing in for the
  # instructor deep-linking each. SyncLtiLineItems' discovery then binds them.
  # `blocks` is the build_full_timeline entries to columnize. Returns 'ok'.
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
        context = binding.lti_contexts.where(user_id: nil).order(:id).first
        raise 'no unlinked context to promote' unless context
        context.update!(user_id: user.id, linked_at: Time.current)
        CoursesUsers.find_or_create_by!(user_id: user.id, course_id: course.id,
                                        role: CoursesUsers::Roles::STUDENT_ROLE)
        puts user.id
      end
    RUBY
    DashboardConsole.run(script).strip
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

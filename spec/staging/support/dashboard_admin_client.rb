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
      slug = "#{school}/#{title.tr(' ', '_')}_(#{term})"
      course = Course.find_or_initialize_by(slug: slug)
      course.assign_attributes(
        title: #{title.inspect},
        school: #{school.inspect},
        term: #{term.inspect},
        start: Date.parse(#{start_date.to_s.inspect}),
        end: Date.parse(#{end_date.to_s.inspect}),
        type: 'ClassroomProgramCourse',
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
end

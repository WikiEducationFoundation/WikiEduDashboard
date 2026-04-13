# frozen_string_literal: true

# Shared example data helpers included in mailer preview classes.
# Provides a realistic unsaved Course and User that mailers can render
# without hitting the database.
module MailerPreviewHelpers
  def example_instructor
    User.new(username: 'Sage (Wiki Ed)', email: 'sage@example.com',
             real_name: 'Sage Ross', permissions: 3)
  end

  # Returns an unsaved Course with realistic attributes and singleton stubs
  # for #instructors and #nonstudents so mailers don't query the database.
  def example_course
    course = Course.new(
      title: 'Advanced Topics in Global Health',
      slug: 'Global_Health/Advanced_Topics_(Spring_2025)',
      school: 'University of Maryland',
      expected_students: 24,
      user_count: 22,
      start: 3.months.ago,
      end: 1.month.from_now,
      revision_count: 450
    )
    stub_instructors(course)
    stub_nonstudents(course)
    course
  end

  private

  def stub_instructors(course)
    instructors = [example_instructor]
    instructors.define_singleton_method(:pluck) { |_col| map(&:email) }
    course.define_singleton_method(:instructors) { instructors }
  end

  def stub_nonstudents(course)
    nonstudents = []
    nonstudents.define_singleton_method(:where) { |**_kwargs| self }
    nonstudents.define_singleton_method(:pluck) { |_col| [] }
    course.define_singleton_method(:nonstudents) { nonstudents }
  end
end

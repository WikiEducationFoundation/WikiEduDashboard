# frozen_string_literal: true

# Aggregate per-professor impact for the "Communicating Science" campaign.
#
# For every instructor (professor / facilitator) who has taught at least one
# course in the campaign, this sums their impact across ALL of their courses in
# that campaign -- not per-course, but the professor's overall footprint.
#
# The output includes all professors (not just 25) so the CSV can be sorted /
# ranked by whichever metric you care about. Rows are sorted by words added
# (descending) by default; take the top 25 of any column to get that leaderboard.
#
# Run it by pasting into a Rails console on the relevant deployment
# (dashboard.wikiedu.org for the Wiki Ed campaign).

require 'csv'

campaign_slug = 'communicating_science'
csv_path = '/tmp/communicating_science_professor_impact.csv'

campaign = Campaign.find_by(slug: campaign_slug)
raise "No campaign with slug #{campaign_slug.inspect}" if campaign.nil?

instructor_role = CoursesUsers::Roles::INSTRUCTOR_ROLE
student_role = CoursesUsers::Roles::STUDENT_ROLE
campaign_course_ids = campaign.courses.pluck(:id)

# Distinct instructors across all courses in the campaign.
instructors = campaign.instructors.distinct.to_a

rows = instructors.map do |instructor|
  # This professor's courses within this campaign (instructor role only).
  courses = Course.where(id: campaign_course_ids)
                  .joins(:courses_users)
                  .where(courses_users: { user_id: instructor.id, role: instructor_role })
                  .distinct

  course_ids = courses.pluck(:id)

  students = CoursesUsers.where(course_id: course_ids, role: student_role)
                         .distinct.count(:user_id)

  {
    name: instructor.real_name,
    username: instructor.username,
    course_count: course_ids.size,
    students:,
    words_added: WordCount.from_characters(courses.sum(:character_sum)),
    references_added: courses.sum(:references_count),
    article_views: courses.sum(:view_sum),
    articles_edited: courses.sum(:article_count),
    articles_created: courses.sum(:new_article_count)
  }
end

# Default ordering: biggest content contribution first.
rows.sort_by! { |row| -row[:words_added] }

CSV.open(csv_path, 'wb') do |csv|
  csv << ['name', 'username', 'course_count', 'students', 'words_added',
          'references_added', 'article_views', 'articles_edited', 'articles_created']
  rows.each do |row|
    csv << [row[:name], row[:username], row[:course_count], row[:students],
            row[:words_added], row[:references_added], row[:article_views],
            row[:articles_edited], row[:articles_created]]
  end
end

puts "Wrote #{rows.size} professors to #{csv_path}"

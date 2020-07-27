# frozen_string_literal: true

# This can be run in the rails console to get a CSV for evaluating unsubmitted courses

require 'csv'

CSV.open("/home/sage/unsubmitted-#{Date.today}.csv", 'wb') do |csv|
  csv << %w[url title instructor first_time_instructor submitted_at expected_students subject level contribution_type assignment_portion sandbox_opinion]
  Course.submitted_but_unapproved.each do |course|
    tags = course.tags.pluck(:tag)
    csv << [
      "https://dashboard.wikiedu.org/courses/#{course.slug}",
      course.title,
      course.instructors.first.real_name,
      tags.include?('first_time_instructor'),
      course.submitted_at,
      course.expected_students,
      course.subject,
      course.level,
      tags.find { |t| t.match /expected_contributions/ },
      tags.find { |t| t.match /assignment_portion/ },
      tags.find { |t| t.match /sandboxes_/ }
    ]
  end
end

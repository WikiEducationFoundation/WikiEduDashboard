# frozen_string_literal: true

namespace :retained_editors do
  desc 'Check and update retained new editors for eligible courses (ended >= 30 days ago)'
  task check: :environment do
    puts 'Checking retained new editors...'
    worker = RetainedEditorCheckWorker.new
    total = worker.perform
    puts "Done! Processed #{total} records."
  end

  desc 'Historical backfill of retained editors with rate-limiting and progress tracking'
  task backfill: :environment do
    puts 'Starting historical backfill for retained new editors...'

    eligible_course_ids = CoursesUsers
                          .joins(:course, :user)
                          .where(role: CoursesUsers::Roles::STUDENT_ROLE, retained_after_course: nil)
                          .where('courses.end <= ?', 30.days.ago)
                          .where(courses: { private: false })
                          .where(NewEditorDateConditions::DURING_PROGRAM)
                          .distinct
                          .pluck(:course_id)

    total_courses = eligible_course_ids.size
    puts "Found #{total_courses} historical courses with unchecked new editors."

    worker = RetainedEditorCheckWorker.new
    total_records = 0

    eligible_course_ids.each_with_index do |course_id, index|
      course = Course.find_by(id: course_id)
      next unless course

      count = worker.check_course_new_editors(course)
      total_records += count

      if ((index + 1) % 10).zero? || index + 1 == total_courses
        puts "[#{index + 1}/#{total_courses} courses] Processed #{total_records} student records so far..."
      end

      # Rate-limiting delay to respect MediaWiki API guidelines
      sleep 0.2
    end

    puts "Historical backfill complete! Total student records updated: #{total_records}"
  end
end

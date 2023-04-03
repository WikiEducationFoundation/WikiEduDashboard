# Script to create a CSV file with aggregate stats for all instructors
# This is basically the same data that shows up on the user profile page.
require Rails.root.join('app/presenters/courses_presenter')

instructors = CoursesUsers.where(role: CoursesUsers::Roles::INSTRUCTOR_ROLE).map(&:user).uniq.compact

CSV.open("/alloc/data/instructors.csv", 'wb') do |csv|
  csv << ['name', 'username', 'course_count', 'student_count', 'student_words_added', 
          'student_refs_added', 'student_pageviews', 'student_articles_edited',
          'student_articles_created', 'student_uploads', 'uploads_in_usge', 'upload_usages']

  instructors.each do |instructor|
    courses = instructor.courses.where(courses_users: { role: CoursesUsers::Roles::INSTRUCTOR_ROLE })
    presenter = CoursesPresenter.new(current_user: nil, courses_list: courses)
    csv << [instructor.real_name, instructor.username, courses.count, presenter.user_count, presenter.word_count,
            presenter.references_count, presenter.view_sum, presenter.article_count,
            presenter.new_article_count, presenter.courses.sum(:upload_count), presenter.uploads_in_use_count, presenter.upload_usage_count]
  end
end

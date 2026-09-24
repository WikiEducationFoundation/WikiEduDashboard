# frozen_string_literal: true

# For an exercise with the article_title_input setting, checks that the student
# has edited the article they name since each course started, and for each
# course where they have, records the article and marks the exercise complete.
class VerifyExerciseArticle
  # The title of the verified article, as normalized by the wiki.
  attr_reader :article_title

  # The courses an exercise can be verified for when the student isn't doing it
  # from a particular course's timeline: current courses that assign the module
  # to the student.
  def self.current_courses(user:, training_module:)
    Course.current
          .joins(:courses_users)
          .where(courses_users: { user_id: user.id, role: CoursesUsers::Roles::STUDENT_ROLE })
          .select { |course| course.training_module_ids.include?(training_module.id) }
  end

  def initialize(training_module_user:, title:, courses:)
    @training_module_user = training_module_user
    @username = training_module_user.user.username
    @title = title.to_s.strip
    @courses = courses
    @verified_courses = []
    perform
  end

  def verified?
    @verified_courses.any?
  end

  private

  def perform
    # A '|' would make the API check several titles at once.
    return if @title.empty? || @title.include?('|')

    @courses.each do |course|
      title = WikiApi.new(course.home_wiki)
                     .title_of_article_edited_by(@username, @title, since: course.start)
      next unless title
      @article_title = title
      @verified_courses << course
      @training_module_user.store_exercise_article_title(title, course.id)
    end
    @training_module_user.save if verified?
  end
end

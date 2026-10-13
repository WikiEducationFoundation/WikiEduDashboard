# frozen_string_literal: true

require_dependency "#{Rails.root}/lib/utils/article_title_input_parser"

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
    @input = ArticleTitleInputParser.new(title)
    @courses = courses
    @verified_courses = []
    perform
  end

  def verified?
    @verified_courses.any?
  end

  private

  def perform
    @courses.each { |course| verify_for(course) }
    @training_module_user.save if verified?
  end

  def verify_for(course)
    wiki_api = WikiApi.new(course.home_wiki)
    title = input_title(wiki_api)
    # A '|' would make the API check several titles at once.
    return if title.blank? || title.include?('|')

    title = wiki_api.title_of_article_edited_by(@username, title, since: course.start)
    return unless title
    @article_title = title
    @verified_courses << course
    @training_module_user.store_exercise_article_title(title, course.id)
  end

  # Links to a revision or page by id carry no title, so the wiki looks it up.
  def input_title(wiki_api)
    return @input.title if @input.title
    return unless @input.revision_id || @input.page_id
    wiki_api.page_title(revision_id: @input.revision_id, page_id: @input.page_id)
  end
end

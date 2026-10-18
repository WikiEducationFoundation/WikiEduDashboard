# frozen_string_literal: true

require_dependency "#{Rails.root}/lib/utils/article_title_input_parser"

# For an exercise with the article_title_input setting, checks that the student
# has edited the page they name since each course started, and for each course
# where they have, records the page and marks the exercise complete. A page
# outside mainspace, such as a sandbox, only counts once the student confirms
# that they mean it.
class VerifyExerciseArticle
  include MediawikiUrlHelper

  # The title of the page, as normalized by the wiki: the verified one, or the
  # one waiting for the student to confirm it.
  attr_reader :article_title, :article_url

  # The courses an exercise can be verified for when the student isn't doing it
  # from a particular course's timeline: current courses that assign the module
  # to the student.
  def self.current_courses(user:, training_module:)
    Course.current
          .joins(:courses_users)
          .where(courses_users: { user_id: user.id, role: CoursesUsers::Roles::STUDENT_ROLE })
          .select { |course| course.training_module_ids.include?(training_module.id) }
  end

  def initialize(training_module_user:, title:, courses:, confirmed: false)
    @training_module_user = training_module_user
    @username = training_module_user.user.username
    @input = ArticleTitleInputParser.new(title)
    @courses = courses
    @confirmed = confirmed
    @verified_courses = []
    @needs_confirmation = false
    perform
  end

  def verified?
    @verified_courses.any?
  end

  # True when the student edited the page they named, but it isn't a mainspace
  # article and they haven't yet confirmed that they mean it.
  def needs_confirmation?
    !verified? && @needs_confirmation
  end

  private

  def perform
    @courses.each { |course| verify_for(course) }
    @training_module_user.save if verified?
  end

  def verify_for(course)
    page = edited_page(course)
    return unless page
    @article_title = page[:title]
    @article_url = "#{course.home_wiki.base_url}/wiki/#{url_encoded_mediawiki_title(page[:title])}"
    unless page[:namespace] == Article::Namespaces::MAINSPACE || @confirmed
      @needs_confirmation = true
      return
    end
    @verified_courses << course
    @training_module_user.store_exercise_article_title(page[:title], course.id)
  end

  def edited_page(course)
    wiki_api = WikiApi.new(course.home_wiki)
    title = input_title(wiki_api)
    # A '|', or a leading U+001F, would make the API check several titles at once.
    return if title.blank? || title.match?(/[|\x1f]/)

    wiki_api.page_edited_by(@username, title, since: course.start)
  end

  # Links to a revision or page by id carry no title, so the wiki looks it up.
  def input_title(wiki_api)
    return @input.title if @input.title
    return unless @input.revision_id || @input.page_id
    wiki_api.page_title(revision_id: @input.revision_id, page_id: @input.page_id)
  end
end

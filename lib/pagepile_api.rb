# frozen_string_literal: true

require_dependency "#{Rails.root}/lib/errors/api_error_handling"

class PagePileApi
  include ApiErrorHandling

  def initialize(category)
    raise 'Wrong category type' unless category.source == 'pileid'
    @category = category
    @wiki = @category.wiki
  end

  def page_titles_for_pileid(update_service: nil)
    fetch_pile_data(update_service:)
    return [] if @pile_data.empty?

    update_language_and_project

    titles = @pile_data['pages']
    titles
  end

  ###################
  # Private methods #
  ###################
  private

  def pileid
    @category.name
  end

  def fetch_pile_data(update_service: nil)
    response = pagepile.get query_url
    @pile_data = Oj.load(response.body)
    url = query_url
  rescue StandardError => e
    log_error(e, update_service:,
              sentry_extra: { api_url: url })
    @pile_data = {}
  end

  # This ensures the Category has the same wiki as the PagePile.
  def update_language_and_project
    language = @pile_data['language']
    project = @pile_data['project']
    return if [@wiki.language, @wiki.project] == [language, project]

    @wiki = Wiki.get_or_create(language:, project:)

    begin
      @category.update(wiki: @wiki)
    rescue ActiveRecord::RecordNotUnique
      handle_category_collision
    end
  end

  # If updating the wiki causes a category collision,
  # the actual desired Category record already exists
  # and we need to update the CategoriesCourses record
  # to point to that one.
  def handle_category_collision
    categories_courses = @category.categories_courses
    existing_category = Category.find_by(wiki: @wiki,
                                         name: @category.name,
                                         depth: @category.depth,
                                         source: @category.source)
    categories_courses.each do |cat_course|
      # Avoid another potential collision.
      if CategoriesCourses.exists?(category: existing_category, course: cat_course.course)
        cat_course.delete
      else
        cat_course.update(category: existing_category)
      end
    end
    existing_category.refresh_titles
    @category.reload # Reload without saving so that calling #save won't retrigger the collision.
  end

  def query_url
    return "https://pagepile.toolforge.org/api.php?id=#{pileid}&action=get_data&format=json"
  end

  def pagepile
    conn = Faraday.new(url: 'https://pagepile.toolforge.org')
    conn.headers['User-Agent'] = ENV['dashboard_url'] + ' ' + Rails.env
    conn
  end

  TYPICAL_ERRORS = [Faraday::TimeoutError,
                    Faraday::ConnectionFailed].freeze
end

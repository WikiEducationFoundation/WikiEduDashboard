# frozen_string_literal: true

require_dependency "#{Rails.root}/lib/replica"
require_dependency "#{Rails.root}/lib/duplicate_article_deleter"
require_dependency "#{Rails.root}/lib/importers/article_importer"

#= Imports and updates revisions from Wikipedia into the dashboard database
class RevisionImporter
  def initialize(wiki, course, update_service: nil)
    @wiki = wiki
    @course = course
    @update_service = update_service
  end

  def import_revisions_for_course(all_time:)
    if all_time
      import_revisions(all_revisions_for_course)
    else
      import_revisions(new_revisions_for_course)
    end
  end

  ###########
  # Helpers #
  ###########
  private

  def all_revisions_for_course
    get_revisions(@course.students, course_start_date, end_of_update_period)
  end

  def new_revisions_for_course
    results = []

    # Users with no revisions are considered "new". For them, we search for
    # revisions starting from the beginning of the course, in case they were
    # just added to the course.
    @new_users = users_with_no_revisions
    results += revisions_from_new_users unless @new_users.empty?

    # For users who already have revisions during the course, we assume that
    # previous updates imported their revisions prior to the latest revisions.
    # We only need to import revisions
    @old_users = @course.students - @new_users
    results += revisions_from_old_users unless @old_users.empty?
    results
  end

  def revisions_from_new_users
    get_revisions(@new_users, course_start_date, end_of_update_period)
  end

  def revisions_from_old_users
    first_rev = latest_revision_of_course
    start = first_rev.blank? ? course_start_date : first_rev.date.strftime('%Y%m%d')
    get_revisions(@old_users, start, end_of_update_period)
  end

  def import_revisions(data)
    # Use revision data fetched from Replica to add new Revisions as well as
    # new Articles where appropriate.
    # Keep it to 100 articles per slice to keep query sizes and lengths reasonable.
    data.each_slice(100) do |sub_data|
      import_revisions_slice(sub_data)
    end
  end

  # Get revisions made by a set of users between two dates.
  def get_revisions(users, start, end_date)
    Utils.chunk_requests(users, 40) do |block|
      Replica.new(@wiki, @update_service).get_revisions block, start, end_date
    end
  end

  def course_start_date
    @course.start.strftime('%Y%m%d')
  end

  # pull all revisions until present, so that we have any after-the-end revisions
  # included for calculating retention when a past course gets updated.
  def end_of_update_period
    2.days.from_now.strftime('%Y%m%d')
  end

  def users_with_no_revisions
    @course.users.role('student')
           .joins(:courses_users)
           .where(courses_users: { revision_count: 0 })
  end

  def latest_revision_of_course
    @course.tracked_revisions.where(wiki_id: @wiki.id).order('date DESC').first
  end

  def import_revisions_slice(sub_data)
    @articles, @revisions = [], []

    # Extract all article data from the slice. Outputs a hash with article attrs.
    articles = sub_data_to_article_attributes(sub_data)

    # We rely on the unique index here
    Article.import articles, on_duplicate_key_update: [:title, :namespace]
    @articles = Article.where(mw_page_id: articles.map { |a| a['mw_page_id'] })

    # Prep: get a user dictionary for all users referred to by revisions.
    users = user_dict_from_sub_data(sub_data)

    # Now get all the revisions
    revisions = sub_data_to_revision_attributes(sub_data, users)
    revisions.flatten!
    Revision.import revisions, on_duplicate_key_ignore: true

    DuplicateArticleDeleter.new(@wiki).resolve_duplicates(@articles)
  end

  def string_to_boolean(string)
    case string
    when 'false'
      false
    when 'true'
      true
    end
  end

  def sanitize_4_byte_titles(title)
    if title.chars.any? { |c| c.bytes.count >= 4 }
      CGI.escape(title)
    else
      title
    end
  end

  def sub_data_to_article_attributes(sub_data)
    sub_data.map do |_a_id, article_data|
      {
        'mw_page_id' => article_data['article']['mw_page_id'],
        'wiki_id' => @wiki.id,
        'title' => sanitize_4_byte_titles(article_data['article']['title']),
        'namespace' => article_data['article']['namespace']
      }
    end
  end

  def user_dict_from_sub_data(sub_data)
    sub_data.map do |_a_id, article_data|
      article_data['revisions'].map { |rev_data| rev_data['username'] }
    end
    users.flatten!
    users.uniq!
    User.where(username: users)
  end

  def sub_data_to_revision_attributes(sub_data, users)
    sub_data.map do |_a_id, article_data|
      article_data['revisions'].map do |rev_data|
        mw_page_id = rev_data['mw_page_id'].to_i
        {
          mw_rev_id: rev_data['mw_rev_id'],
          date: rev_data['date'],
          characters: rev_data['characters'],
          article_id: @articles.find { |a| a.mw_page_id == mw_page_id }&.id,
          mw_page_id: mw_page_id,
          user_id: users.find { |u| u.username == rev_data['username'] }&.id,
          new_article: string_to_boolean(rev_data['new_article']),
          system: string_to_boolean(rev_data['system']),
          wiki_id: rev_data['wiki_id']
        }
      end
    end
  end
end

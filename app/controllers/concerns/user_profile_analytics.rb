# frozen_string_literal: true

module UserProfileAnalytics
  extend ActiveSupport::Concern

  def course_article_data(cu)
    ac_records = ArticlesCourses.tracked_for_user_and_course(cu.course, @user.id)
    articles = format_articles(ac_records)

    return nil unless articles.any? || 
                      cu.character_sum_ms.positive? || 
                      cu.references_count.positive?

    {
      course_title: cu.course.title,
      course_slug: cu.course.slug,
      word_count: WordCount.from_characters(cu.character_sum_ms),
      references_count: cu.references_count,
      articles_edited: articles.length,
      articles:
    }
  end

  def format_articles(ac_records)
    ac_records.map do |ac|
      {
        article_id: ac.article.id,
        title: ac.article.title,
        url: ac.article.url,
        word_count: WordCount.from_characters(ac.character_sum.to_i),
        references_count: ac.references_count.to_i
      }
    end
  end

  def max_project
    ids_array = public_courses.map(&:home_wiki_id)
    max_ids = ids_array.tally.select { |_k, v| v == ids_array.tally.values.max }.keys
    projects = Wiki.where(id: max_ids).map(&:project)
    projects.include?('wikipedia') ? 'wikipedia' : projects[0]
  end

  def get_articles_by_language
    # Group the user's individual contributions by the home wiki of each course
    # they were enrolled in as a student. This keeps the per-language totals
    # consistent with the top-level "Words Added" / "References Added" /
    # "Articles Edited" metrics, which are all computed per-user from
    # CoursesUsers#character_sum_ms / #references_count and the user-filtered
    # ArticlesCourses records.
    courses_users = @user.courses_users
                         .includes(course: :home_wiki)
                         .joins(:course)
                         .where(courses: { private: false })
                         .where(role: CoursesUsers::Roles::STUDENT_ROLE)

    course_ids = courses_users.map(&:course_id).uniq
    return [] if course_ids.empty?

    # Per-user, per-course article counts (mainspace, non-deleted), matching
    # the scope used by IndividualStatisticsTimeslicePresenter#individual_article_count.
    articles_count_by_course = ArticlesCourses
                                 .where('user_ids LIKE ?', "%- #{@user.id}\n%")
                                 .where(course_id: course_ids)
                                 .joins(:article)
                                 .where(articles: { deleted: false,
                                                    namespace: Article::Namespaces::MAINSPACE })
                                 .group(:course_id)
                                 .count

    grouped = {}
    courses_users.each do |cu|
      wiki = cu.course.home_wiki
      language = wiki&.language || 'unknown'
      project = wiki&.project || 'unknown'
      key = "#{language}-#{project}"

      grouped[key] ||= {
        language:,
        project:,
        character_sum: 0,
        references_count: 0,
        article_count: 0
      }

      grouped[key][:character_sum] += cu.character_sum_ms.to_i
      grouped[key][:references_count] += cu.references_count.to_i
      grouped[key][:article_count] += articles_count_by_course[cu.course_id].to_i
    end

    grouped.values.map do |v|
      {
        language: v[:language],
        project: v[:project],
        word_count: WordCount.from_characters(v[:character_sum]),
        references_count: v[:references_count],
        article_count: v[:article_count]
      }
    end.sort_by { |v| -v[:word_count] }
  end

  def public_courses
    @user.courses.nonprivate
  end

  private

  def require_write_permissions
    return if current_user == @user
    raise ActionController::InvalidAuthenticityToken, 'Unauthorized'
  end

  def require_email_preferences_token
    return if @user_profile.email_preferences_token == params[:token]
    raise ActionController::InvalidAuthenticityToken, 'Unauthorized'
  end

  def user_profile_params
    params.require(:user_profile).permit(:bio, :image, :location, :institution, :image_file_link)
  end

  def user_email_params
    params.require(:email).permit(:email)
  end

  def email_must_be_present_for_instructors
    return unless current_user.active_course_instructor?
    submitted_email = user_email_params[:email].to_s.strip

    return if submitted_email.present?

    @user.errors.add(:email, :blank, message: I18n.t('users.email_required_instructor'))
    flash[:error] = I18n.t('users.email_required_instructor')
  end

  def user_profile_redirect
    redirect_to controller: 'user_profiles', action: 'show', username: @user.username
  end

  def set_user
    # Per MediaWiki convention, underscores in username urls represent spaces
    username = CGI.unescape(params[:username]).tr('_', ' ')
    @user = User.find_by(username:)
  end

  def set_user_profile
    @user_profile = @user.user_profile
    @user_profile = @user.create_user_profile if @user_profile.nil?
  end
end
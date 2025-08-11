# frozen_string_literal: true

require_dependency "#{Rails.root}/lib/word_count"

# Presenter to provide statistics about a user's individual contributions during
# courses in which the user was a student.
class IndividualStatisticsTimeslicePresenter
  def initialize(user:)
    @user = user
    set_data_from_course_user
    set_data_from_article_course
    set_upload_usage_counts
  end

  def individual_courses
    @individual_courses ||= @user.courses.nonprivate.where(courses_users: { role: CoursesUsers::Roles::STUDENT_ROLE }) # rubocop:disable Layout/LineLength
  end

  def course_string_prefix
    Features.default_course_string_prefix
  end

  def individual_word_count
    WordCount.from_characters individual_character_count
  end

  def individual_character_count
    @course_user_data[:characters]
  end

  def individual_references_count
    @course_user_data[:references]
  end

  def individual_upload_count
    @upload_usage_counts.length
  end

  def individual_upload_usage_count
    @upload_usage_counts.values.sum
  end

  def individual_article_count
    @article_course_data.length
  end

  private

  def set_data_from_course_user
    @course_user_data = {}
    @course_user_data[:characters] = 0
    @course_user_data[:references] = 0

    course_user_records(individual_courses.pluck(:id)).each do |course_user|
      @course_user_data[:characters] += course_user.character_sum_ms
      @course_user_data[:references] += course_user.references_count
    end
  end

  def set_data_from_article_course
    @article_course_data = {}
    article_course_records(individual_courses.pluck(:id)).each do |article_course|
      @article_course_data[article_course.article_id] = 1
    end
  end

  def set_upload_usage_counts
    @upload_usage_counts = {}

    # Get the earliest start date from all individual courses
    start_date = individual_courses.map(&:start).min.strftime('%Y-%m-%d %H:%M:%S')
    # Get the latest end date from all individual courses
    end_date = individual_courses.map(&:end).max.strftime('%Y-%m-%d %H:%M:%S')

    # Query all uploads for this user within the combined date range
    common_upload_data = CommonsUpload.where(user_id: @user.id)
                                      .where('uploaded_at >= ? AND uploaded_at <= ?', start_date, end_date) # rubocop:disable Layout/LineLength
                                      .select(:id, :usage_count)

    common_upload_data.each do |upload|
      @upload_usage_counts[upload.id] = upload.usage_count || 0
    end
  end

  def article_course_records(course_id)
    ArticlesCourses
      .where('user_ids LIKE ?', "%- #{@user.id}\n%")
      .where(course_id:)
      .joins(:article)
      .where(articles: { namespace: Article::Namespaces::MAINSPACE, deleted: false })
      .select(:article_id)
  end

  def course_user_records(course_id)
    @course_user_records ||= CoursesUsers.where(course_id:, user: @user).select(:character_sum_ms,
                                                                                :references_count)
  end
end

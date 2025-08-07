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
    @user.courses.nonprivate.where(courses_users: { role: CoursesUsers::Roles::STUDENT_ROLE })
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
    individual_courses.each do |course|
      article_course_records(course).each do |article_course|
        @article_course_data[article_course.article_id] = 1
      end
    end
  end

  def set_upload_usage_counts
    @upload_usage_counts = {}
    individual_courses.each do |course|
      course.uploads.where(user_id: @user.id).each do |upload|
        @upload_usage_counts[upload.id] = upload.usage_count || 0
      end
    end
  end

  def article_course_records(course)
    course.articles_courses
          .where('user_ids LIKE ?', "%- #{@user.id}\n%")
          .joins(:article)
          .includes(:article)
          .where(articles: { namespace: Article::Namespaces::MAINSPACE, deleted: false })
  end

  def course_user_records(course_id)
    @course_user_records ||= CoursesUsers.where(course_id:, user: @user).select(:character_sum_ms,
                                                                                :references_count)
  end
end

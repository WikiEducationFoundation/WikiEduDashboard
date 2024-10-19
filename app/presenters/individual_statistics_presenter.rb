# frozen_string_literal: true

require_dependency "#{Rails.root}/lib/word_count"

# Presenter to provide statistics about a user's individual contributions during
# courses in which the user was a student.
class IndividualStatisticsPresenter
  def initialize(user:)
    @user = user
    set_articles_created
    set_article_views
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
    @articles_created.values.sum do |article|
      article[:characters].values.inject(0) do |sum, characters|
        characters&.positive? ? sum + characters : sum
      end
    end
  end

  def individual_references_count
    @articles_created.values.sum do |article|
      article[:references].values.inject(0) do |sum, references|
        references ? sum + references : sum
      end
    end
  end

  def individual_upload_count
    @upload_usage_counts.length
  end

  def individual_upload_usage_count
    @upload_usage_counts.values.sum
  end

  def individual_article_count
    @articles_created.count
  end

  # going
  def individual_article_views
    @articles_created.values.sum { |article| article[:average_views] }
  end

  def individual_articles_created
    @articles_created.values.count { |articles| articles[:new_article] }
  end

  private

  # rubocop:disable Metrics/AbcSize
  def set_articles_created
    @articles_created = {}
    individual_courses.each do |course|
      course.articles_courses.each do |edit|
        if edit.user_ids.include?(@user.id)
          articles = @articles_created[edit.article_id] || { new_article: false,
                                                                  views: 0,
                                                                  characters: {},
                                                                  references: {} }
          articles[:characters][0] ||= edit.character_sum
          articles[:references][1] ||= edit.references_count
          articles[:average_views] ||= edit.article.average_views
          @articles_created[edit.article_id] = articles
        end
      end
    end
  end
  # rubocop:enable Metrics/AbcSize

  def set_article_views
    @articles_created.each do |_article_id, articles|
      next 
      days = (Time.now.utc.to_date - articles[:earliest_revision].to_date).to_i
      articles[:views] = days * articles[:average_views]
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
end

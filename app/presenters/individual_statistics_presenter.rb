# frozen_string_literal: true

require_dependency "#{Rails.root}/lib/word_count"

# Presenter to provide statistics about a user's individual contributions during
# courses in which the user was a student.
class IndividualStatisticsPresenter
  def initialize(user:)
    @user = user
    set_articles_edited
    set_upload_usage_counts
  end

  def individual_courses
    @user.courses.nonprivate.where('courses_users.role = ?', CoursesUsers::Roles::STUDENT_ROLE)
  end

  def course_string_prefix
    Features.default_course_string_prefix
  end

  def individual_word_count
    WordCount.from_characters individual_character_count
  end

  def individual_character_count
    @articles_edited.values.sum do |article|
      article[:characters].values.inject(0) do |sum, characters|
        characters&.positive? ? sum + characters : sum
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
    @articles_edited.count
  end

  def individual_article_views
    @articles_edited.values.sum { |article| article[:views] }
  end

  def individual_articles_created
    @articles_edited.values.select { |article_edits| article_edits[:new_article] }.count
  end

  private

  def set_articles_edited
    @articles_edited = {}
    individual_courses.each do |course|
      individual_mainspace_edits(course).each do |edit|
        article_edits = @articles_edited[edit.article_id] || { new_article: false,
                                                               views: 0, characters: {} }
        article_edits[:characters][edit.mw_rev_id] = edit.characters
        article_edits[:new_article] = true if edit.new_article
        # highest view count of all revisions for this article is the total for the article
        article_edits[:views] = edit.views if edit.views > article_edits[:views]
        @articles_edited[edit.article_id] = article_edits
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

  def individual_mainspace_edits(course)
    course.all_revisions
          .joins(:article)
          .where(articles: { namespace: Article::Namespaces::MAINSPACE })
          .where(user: @user, deleted: false)
  end
end

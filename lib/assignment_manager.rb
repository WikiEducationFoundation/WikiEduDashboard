# frozen_string_literal: true

# Tested via AssignmentsController
require_dependency "#{Rails.root}/lib/article_utils"
require_dependency "#{Rails.root}/lib/importers/rating_importer"
require_dependency "#{Rails.root}/lib/importers/article_importer"

class AssignmentManager
  def initialize(course:, user_id: nil, wiki: nil, title: nil, role: nil)
    @course = course
    @user_id = user_id
    @wiki = wiki
    @title = title
    @role = role
  end

  def create_random_peer_reviews
    peer_review_count = @course.peer_review_count || 1

    @course.students.each do |student|
      currently_reviewing = @course.assignments.reviewing
                                   .where(user_id: student.id).pluck(:article_title)
      needed_count = peer_review_count - currently_reviewing.count
      next unless needed_count.positive?

      reviewables = reviewable_titles(student, needed_count, currently_reviewing)

      assign_peer_reviews(student, reviewables)
    end
  end

  def create_assignment
    set_clean_title
    set_article_from_database
    import_article_from_wiki unless @article
    # TODO: update rating via Sidekiq worker
    update_article_rating if @article
    Assignment.create!(user_id: @user_id, course: @course,
                       article_title: @clean_title, wiki: @wiki, article: @article,
                       role: @role)
  rescue ActiveRecord::RecordInvalid
    raise DuplicateAssignmentError, "#{@clean_title} is already assigned to this user."
  end

  private

  def assigned_titles
    @assigned_titles ||= @course.assignments.assigned.pluck(:article_title).uniq
  end

  def reviewed_titles
    @newly_reviewed_titles ||= []
    @initially_reviewed_titles ||= @course.assignments.reviewing.pluck(:article_title).uniq
    @initially_reviewed_titles + @newly_reviewed_titles
  end

  def own_assigned_titles(student)
    @course.assignments.assigned.where(user_id: student.id).pluck(:article_title).uniq
  end

  def unreviewed_peer_titles(student)
    assigned_titles - reviewed_titles - own_assigned_titles(student)
  end

  def reviewable_titles(student, needed_count, currently_reviewing)
    reviewables = unreviewed_peer_titles(student)
    if reviewables.count > needed_count
      reviewables = reviewables.shuffle.take(needed_count)
    elsif reviewables.count < needed_count
      reviewables += @course.assignments.assigned
                            .where.not(user_id: student.id)
                            .where.not(article_title: currently_reviewing)
                            .sample(needed_count - reviewables.count)
                            .pluck(:article_title)
    end
    reviewables
  end

  def set_clean_title
    # Wiktionary allows titles that begin lower case.
    # Other projects enforce capitalization of the first letter.
    @clean_title = if @wiki.project == 'wiktionary'
                     @title.tr(' ', '_')
                   else
                     ArticleUtils.format_article_title(@title)
                   end
  end

  def set_article_from_database
    # We double check that the titles are equal to avoid false matches of case variants.
    # We can revise this once the database is set to use case-sensitive collation.
    articles = Article.where(title: @clean_title, wiki_id: @wiki.id,
                             namespace: Article::Namespaces::MAINSPACE)
    exact_title_matches = articles.select { |article| article.title == @clean_title }
    @article = exact_title_matches.first
  end

  def import_article_from_wiki
    ArticleImporter.new(@wiki).import_articles_by_title([@clean_title])
    set_article_from_database
  end

  def update_article_rating
    RatingImporter.update_rating_for_article(@article)
  end

  def assign_peer_reviews(student, reviewable_titles)
    reviewable_titles.each do |title|
      Assignment.create!(user_id: student.id, course: @course,
                         article_title: title, wiki: @wiki,
                         role: Assignment::Roles::REVIEWING_ROLE)
      @newly_reviewed_titles << title
    end
  end

  class DuplicateAssignmentError < StandardError; end
end

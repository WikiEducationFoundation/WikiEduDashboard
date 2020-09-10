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
                                   .where(user_id: student.id).pluck(:article_id)
      next if currently_reviewing.length > peer_review_count

      unreviewed_peer_assignments = @course.assignments.assigned
                                           .where.not(user_id: student.id,
                                                      article_id: currently_reviewing)
      randomly_assign_peer_reviews(student, unreviewed_peer_assignments,
                                   peer_review_count - currently_reviewing.length)
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

  def randomly_assign_peer_reviews(student, potential_assignments, count)
    potential_assignments.sample(count).each do |random_assignment|
      Assignment.create!(user_id: student.id, course: @course,
                         article_title: random_assignment.article_title, wiki: @wiki,
                         article_id: random_assignment.article_id,
                         role: Assignment::Roles::REVIEWING_ROLE)
    end
  end

  class DuplicateAssignmentError < StandardError; end
end

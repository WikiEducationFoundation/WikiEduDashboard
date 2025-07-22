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
    check_wiki_edu_discouraged_article
    set_available_article_flag
    import_article_from_wiki unless @article
    # TODO: update rating via Sidekiq worker
    update_article_rating if @article
    set_available_article_flag
    Assignment.create!(user_id: @user_id, course: @course, article_title: @clean_title,
                       wiki: @wiki, article: @article, role: @role, flags: @flags)
  rescue ActiveRecord::RecordInvalid => e
    message = if e.message.include?('invalid')
                "#{@clean_title} is not a valid article title."
              else
                "#{@clean_title} is already assigned to this user."
              end
    raise DuplicateAssignmentError, message
  end

  def claim_assignment(claimed_assignment)
    @wiki = claimed_assignment.wiki
    @title = claimed_assignment.article_title
    @role = Assignment::Roles::ASSIGNED_ROLE
    if @course.retain_available_articles?
      create_assignment
    else
      claimed_assignment.update(user_id: @user_id)
      claimed_assignment
    end
  end

  private

  def assigned_titles
    @assigned_titles ||= @course.assignments.assigned
                                .where(user: @course.students).pluck(:article_title).shuffle
  end

  def reviewed_titles
    @course.assignments.reviewing
           .pluck(:article_title)
  end

  def review_counts
    @review_counts ||= reviewed_titles.each_with_object(Hash.new(0)) do |title, title_counts|
      title_counts[title] += 1
    end
  end

  def own_assigned_titles(student)
    @course.assignments.assigned.where(user_id: student.id).pluck(:article_title)
  end

  def reviewable_titles(student, needed_count, currently_reviewing)
    # all classmates' assigned titles that aren't assigned to this student
    # and the student isn't already reviewing it
    possible_reviews = assigned_titles.uniq - currently_reviewing - own_assigned_titles(student)
    # order by fewest reviews
    possible_reviews.sort_by { |title| review_counts[title] }.take(needed_count)
  end

  def set_clean_title
    # Wiktionary allows titles that begin lower case.
    # Other projects enforce capitalization of the first letter.
    @clean_title = ArticleUtils.format_article_title(@title, @wiki)
  end

  def set_article_from_database
    # We double check that the titles are equal to avoid false matches of case variants.
    # We can revise this once the database is set to use case-sensitive collation.
    articles = Article.where(title: @clean_title, wiki_id: @wiki.id,
                             namespace: Article::Namespaces::MAINSPACE)
    exact_title_matches = articles.select { |article| article.title == @clean_title }
    @article = exact_title_matches.first
  end

  def check_wiki_edu_discouraged_article
    category = Category.find_by(name: ENV['blocked_assignment_category'])
    article_discouraged = (category.present? && category.article_titles.include?(@clean_title))
    handle_discouraged_article if article_discouraged
  end

  def handle_discouraged_article
    raise DiscouragedArticleError, I18n.t('assignments.blocked_assignment', title: @clean_title)
  end

  def set_available_article_flag
    @flags = @user_id.nil? ? { available_article: true } : nil
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
      review_counts[title] += 1
    end
  end

  class DuplicateAssignmentError < StandardError; end
  class DiscouragedArticleError < StandardError; end
end

# frozen_string_literal: true
require "#{Rails.root}/lib/article_utils"

class AssignmentManager
  def initialize(course:, user_id:, wiki:, title:, role:)
    @course = course
    @user_id = user_id
    @wiki = wiki
    @title = title
    @role = role
  end

  def create_assignment
    set_clean_title
    set_article_from_database
    import_article_from_wiki unless @article

    # We double check that the titles are equal to avoid false matches of case variants.
    # We can revise this once the database is set to use case-sensitive collation.
    @article_id = @article.id if @article && @article.title == @clean_title
    Assignment.create!(user_id: @user_id, course_id: @course.id,
                       article_title: @clean_title, wiki_id: @wiki.id, article_id: @article_id,
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
    @article = Article.find_by(title: @clean_title, wiki_id: @wiki.id,
                               namespace: Article::Namespaces::MAINSPACE)
  end

  def import_article_from_wiki
    ArticleImporter.new(@wiki).import_articles_by_title([@clean_title])
    set_article_from_database
  end

  class DuplicateAssignmentError < StandardError; end
end

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
    @clean_title = ArticleUtils.format_article_title(@title)
    article = Article.find_by(title: @clean_title, wiki_id: @wiki.id,
                              namespace: Article::Namespaces::MAINSPACE)
    # We double check that the titles are equal to avoid false matches of case variants.
    # We can revise this once the database is set to use case-sensitive collation.
    @article_id = article.id if article && article.title == @clean_title
    # TODO: try to fetch article from wiki if not found locally
    Assignment.create!(user_id: @user_id,
                       course_id: @course.id,
                       article_title: @clean_title,
                       wiki_id: @wiki.id,
                       article_id: @article_id,
                       role: @role)
  end
end

require "#{Rails.root}/lib/importers/category_importer"

class ArticlesForDeletionMonitor
  def initialize
    @wiki = Wiki.find_by(language: 'en', project: 'wikipedia')
    find_deletion_discussions
    find_page_titles
    create_alerts
  end

  private

  def find_deletion_discussions
    category = 'Category:AfD debates'
    depth = 2
    @afd_titles ||= CategoryImporter.new(@wiki).page_titles_for_category(category, depth)
  end

  def create_alerts
    local_articles = Article.where(title: @page_titles, namespace: Article::Namespaces::MAINSPACE)
    local_articles.each do |article|
      pp article
    end
  end

  def find_page_titles
    titles = @afd_titles.map do |afd_title|
      title = afd_title[%r{Wikipedia:Articles for deletion/(.*)}, 1]
      next unless title
      title.tr(' ', '_')
    end
    @page_titles = titles.compact!
  end
end

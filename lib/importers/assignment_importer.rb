#= Keeps assignments updated to match moving articles
class AssignmentImporter
  # Update article ids for Assignments that lack them, if an Article with the
  # same title exists in mainspace.
  def self.update_assignment_article_ids
    ActiveRecord::Base.transaction do
      Assignment.where(article_id: nil).each do |ass|
        title = ass.article_title.gsub(' ', '_')
        article = Article.where(namespace: 0).find_by(title: title)
        ass.article_id = article.nil? ? nil : article.id
        ass.save
      end
    end
  end
end

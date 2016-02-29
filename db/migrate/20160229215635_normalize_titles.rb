class NormalizeTitles < ActiveRecord::Migration
  def up
    execute "update articles set title = replace(title, ' ', '_')"
    execute "update assignments set article_title = replace(article_title, ' ', '_')"
  end
end

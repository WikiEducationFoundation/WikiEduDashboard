class NormalizeTitles < ActiveRecord::Migration[4.2]
  # Causing migration issues, commenting out

  # def up
  #   execute "update articles set title = replace(title, ' ', '_')"
  #   Assignment.all.each do |assignment|
  #     update_assignment(assignment)
  #   end
  # end

  # private

  # def update_assignment(assignment)
  #   assignment.article_title = Utils.format_article_title(assignment.article_title)
  #   assignment.save
  # rescue ActiveRecord::RecordNotUnique
  #   assignment.destroy
  # end
end

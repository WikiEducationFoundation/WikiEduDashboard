json.assignments course.assignments.includes(:user).group_by(:article_title) do |title, ass_group|
  json.title title
  json.assignees ass_group.find_all{ |a| a.role == 0 } do |assignee|
    json.wiki_id assignee.user.wiki_id
  end
  json.reviewers ass_group.find_all{ |a| a.role == 1 } do |reviewer|
    json.wiki_id reviewer.user.wiki_id
  end
end
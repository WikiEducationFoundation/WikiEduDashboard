#= Helpers for course views
module CourseHelper
  def contribution_link(user, text=nil, css_class=nil)
    options = { target: '_blank', class: css_class }
    link_to((text || user.wiki_id), user.contribution_url, options)
  end

  def user_links(users, css_class=nil)
    value = ''
    users.each_with_index do |u, i|
      value += i > 0 ? '<br>'.html_safe : ''
      value += contribution_link(u, nil, css_class)
    end
    value.html_safe
  end
  
end

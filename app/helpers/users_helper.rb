#= Helpers for users
module UsersHelper
  def contribution_link(courses_user, text=nil, css_class=nil)
    options = { target: '_blank', class: css_class }
    link_to((text || courses_user.user.username), courses_user.contribution_url, options)
  end
end

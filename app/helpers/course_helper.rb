#= Helpers for course views
module CourseHelper
  def user_links(users, css_class=nil)
    value = ''
    users.each_with_index do |u, i|
      value += i > 0 ? '<br>'.html_safe : ''
      value += contribution_link(u, nil, css_class)
    end
    value.html_safe
  end

  def current?(course)
    # FIXME: 'current' should only be defined in one place. It's also defined
    # from an application.yml parameter in course.rb
    month = 2_592_000 # number of seconds in 30 days
    course.start < Time.now && course.end > Time.now - month
  end
end

# Alert for users that "Need Help"
class NeedHelpAlert < Alert
  def main_subject
    "#{user.username} / #{course.slug}"
  end

  def url
    course_url
  end
end

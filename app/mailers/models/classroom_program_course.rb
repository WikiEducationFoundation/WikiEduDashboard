# == Schema Information
#
# Table name: courses
#
#  id                :integer          not null, primary key
#  title             :string(255)
#  created_at        :datetime
#  updated_at        :datetime
#  start             :date
#  end               :date
#  school            :string(255)
#  term              :string(255)
#  character_sum     :integer          default(0)
#  view_sum          :integer          default(0)
#  user_count        :integer          default(0)
#  article_count     :integer          default(0)
#  revision_count    :integer          default(0)
#  slug              :string(255)
#  listed            :boolean          default(TRUE)
#  signup_token      :string(255)
#  assignment_source :string(255)
#  subject           :string(255)
#  expected_students :integer
#  description       :text(65535)
#  submitted         :boolean          default(FALSE)
#  passcode          :string(255)
#  timeline_start    :date
#  timeline_end      :date
#  day_exceptions    :string(2000)     default("")
#  weekdays          :string(255)      default("0000000")
#  new_article_count :integer
#  no_day_exceptions :boolean          default(FALSE)
#  trained_count     :integer          default(0)
#  cloned_status     :integer
#  type              :string(255)      default("ClassroomProgramCourse")
#

class ClassroomProgramCourse < Course
  def wiki_edits_enabled?
    true
  end

  def wiki_title
    prefix = ENV['course_prefix'] + '/'
    escaped_slug = slug.tr(' ', '_')
    "#{prefix}#{escaped_slug}"
  end

  def string_prefix
    'courses'
  end
end

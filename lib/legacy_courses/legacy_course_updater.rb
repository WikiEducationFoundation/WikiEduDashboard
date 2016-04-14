require "#{Rails.root}/lib/legacy_courses/legacy_course_importer"
require "#{Rails.root}/lib/legacy_courses/legacy_course_user_importer"

class LegacyCourseUpdater
  def self.update_from_wiki(course, data={}, save=true)
    if data.blank?
      data = LegacyCourseImporter.get_course_info course.id
      return if data.blank? || data[0].nil?
      data = data[0]
    end
    # Symbol if coming from controller, string if from course importer
    course.attributes = data[:course] || data['course']

    return unless save

    participant_data = data['participants']
    import_participant_data(participant_data, course) if participant_data

    course.save
  end

  def self.import_participant_data(data, course)
    data.each_with_index do |(r, _p), i|
      LegacyCourseUserImporter.add_users(data[r], i, course)
    end
  end
end

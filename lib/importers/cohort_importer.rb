#= Imports and updates cohorts
class CohortImporter
  # Take a hash of cohorts and corresponding course_ids, and update the cohorts.
  # raw_ids is the output of Wiki.course_list, and looks like this:
  # { "cohort_slug" => [31, 554, 1234], "cohort_slug_2" => [31, 999, 2345] }
  def self.update_cohorts(raw_ids)
    Course.transaction do
      raw_ids.each do |ch, ch_courses|
        cohort = Cohort.find_or_create_by(slug: ch)
        ch_new = ch_courses - cohort.courses.map(&:id)
        ch_old = cohort.courses.map(&:id) - ch_courses
        ch_new.each do |co|
          course = Course.find_by_id(co)
          course.cohorts << cohort if course
        end
        ch_old.each do |co|
          course = Course.find_by_id(co)
          course.cohorts.delete(cohort) if course
        end
      end
    end
  end
end

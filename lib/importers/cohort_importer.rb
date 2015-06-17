#= Imports and updates cohorts
class CohortImporter
  # Take a hash of cohorts and corresponding course_ids, and update the cohorts.
  # raw_ids is the output of Wiki.course_list, and looks like this:
  # { "cohort_slug" => [31, 554, 1234], "cohort_slug_2" => [31, 999, 2345] }
  def self.update_cohorts(raw_ids)
    Course.transaction do
      raw_ids.each do |slug, course_ids|
        cohort = Cohort.find_or_create_by(slug: slug)
        ids_in_cohort = cohort.courses.map(&:id)
        new_course_ids = course_ids - ids_in_cohort
        removed_course_ids = ids_in_cohort - course_ids

        add_courses_to_cohort(new_course_ids, cohort)
        remove_courses_from_cohort(removed_course_ids, cohort)
      end
    end
  end

  def self.add_courses_to_cohort(new_course_ids, cohort)
    new_course_ids.each do |course_id|
      new_course = Course.find_by_id(course_id)
      new_course.cohorts << cohort if new_course
    end
  end

  def self.remove_courses_from_cohort(removed_course_ids, cohort)
    removed_course_ids.each do |course_id|
      removed_course = Course.find_by_id(course_id)
      removed_course.cohorts.delete(cohort) if removed_course
    end
  end
end

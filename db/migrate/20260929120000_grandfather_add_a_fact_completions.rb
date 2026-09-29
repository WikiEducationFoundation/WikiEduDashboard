# frozen_string_literal: true

# The "Add a fact" module (id 69) becomes an exercise, which counts as complete
# per course via flags[course_id][:marked_complete] rather than completed_at.
# Students who already finished its slides would otherwise lose that completion
# (in course stats, timelines, and LTI grades) when trainings are next reloaded.
# This marks it complete in each course where it currently counts as complete:
# every course the student is in that assigns the module.
#
# Until trainings are reloaded the module is still a training, which ignores
# these flags, so running this at deploy time changes nothing visible.
class GrandfatherAddAFactCompletions < ActiveRecord::Migration[7.0]
  MODULE_ID = 69
  STUDENT_ROLE = 0

  # Stand-ins for the models, so later changes to them don't affect this.
  class TrainingModulesUser < ActiveRecord::Base
    self.table_name = 'training_modules_users'
    serialize :flags, type: Hash
  end

  class CoursesUser < ActiveRecord::Base
    self.table_name = 'courses_users'
  end

  class Block < ActiveRecord::Base
    self.table_name = 'blocks'
    serialize :training_module_ids, type: Array
  end

  def up
    course_ids_by_user = student_course_ids_by_user(courses_assigning_module)
    TrainingModulesUser.where(training_module_id: MODULE_ID).where.not(completed_at: nil)
                       .find_each do |tmu|
      course_ids = course_ids_by_user[tmu.user_id]
      next if course_ids.blank?
      grandfather(tmu, course_ids)
    end
  end

  # The flags are harmless if the module goes back to being a training, and a
  # grandfathered completion can't be told apart from a verified one.
  def down; end

  private

  def courses_assigning_module
    Block.joins('INNER JOIN weeks ON weeks.id = blocks.week_id')
         .where.not('training_module_ids = ?', [].to_yaml)
         .pluck('weeks.course_id', :training_module_ids)
         .select { |_course_id, module_ids| module_ids.include?(MODULE_ID) }
         .map(&:first).uniq
  end

  def student_course_ids_by_user(course_ids)
    CoursesUser.where(role: STUDENT_ROLE, course_id: course_ids)
               .pluck(:user_id, :course_id)
               .group_by(&:first).transform_values { |rows| rows.map(&:last) }
  end

  # Leaves alone any course where the exercise already has a completion status.
  def grandfather(tmu, course_ids)
    flags = tmu.flags || {}
    course_ids.each do |course_id|
      next if flags[course_id].is_a?(Hash) && flags[course_id].key?(:marked_complete)
      flags[course_id] = (flags[course_id] || {}).merge(marked_complete: true)
    end
    tmu.update_column(:flags, flags) # rubocop:disable Rails/SkipsModelValidations
  end
end

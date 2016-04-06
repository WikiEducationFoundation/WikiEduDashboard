module QuestionGroupsHelper
  def check_conditionals(question_group)
    return true if @notification == false
    @question_group_cohorts = question_group.cohorts.pluck(:id)
    @question_group_tags = question_group.tags.split(',')
    @course = @notification.course
    course_has_tags && course_in_cohorts
  end

  def course_has_tags
    return true if @question_group_tags.empty?
    course_tags = @course.tags.pluck(:tag)
    matching = course_tags.select do |t|
      @question_group_tags.include?(t)
    end
    matching.length == @question_group_tags.length
  end

  def course_in_cohorts
    return true if @question_group_cohorts.empty?
    matching = @question_group_cohorts.select do |cohort_id|
      CohortsCourses.where(course_id: @course.id, cohort_id: cohort_id).count > 0
    end
    matching.count == @question_group_cohorts.count
  end
end

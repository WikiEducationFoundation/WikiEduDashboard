# frozen_string_literal: true

module QuestionGroupsHelper
  def course_meets_conditions_for_question_group?(question_group)
    ConditionChecker.new(question_group, @course).meets_conditions?
  end

  class ConditionChecker
    def initialize(question_group, course)
      @question_group = question_group
      @course = course
      @question_group_campaigns_ids = question_group.campaigns.pluck(:id)
      @question_group_tags = question_group.tags.split(',')
    end

    def meets_conditions?
      course_has_all_tags && course_in_all_campaigns
    end

    private

    def course_has_all_tags
      return true if @question_group_tags.empty?
      return false if @course.nil?

      course_tags = @course.tags.pluck(:tag)
      matching = course_tags.select do |t|
        @question_group_tags.include?(t)
      end
      matching.length == @question_group_tags.length
    end

    def course_in_all_campaigns
      return true if @question_group_campaigns_ids.empty?
      return false if @course.nil?

      matching = @question_group_campaigns_ids.select do |campaign_id|
        CampaignsCourses.where(course_id: @course.id, campaign_id: campaign_id).any?
      end
      matching.count == @question_group_campaigns_ids.count
    end
  end
end

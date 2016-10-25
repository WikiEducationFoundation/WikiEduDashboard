# frozen_string_literal: true
module QuestionGroupsHelper
  def check_conditionals(question_group)
    return true if @course.nil?
    @question_group_campaigns = question_group.campaigns.pluck(:id)
    @question_group_tags = question_group.tags.nil? ? [] : question_group.tags.split(',')
    course_has_tags && course_in_campaigns
  end

  def course_has_tags
    return true if @question_group_tags.empty?
    course_tags = @course.tags.pluck(:tag)
    matching = course_tags.select do |t|
      @question_group_tags.include?(t)
    end
    matching.length == @question_group_tags.length
  end

  def course_in_campaigns
    return true if @question_group_campaigns.empty?
    matching = @question_group_campaigns.select do |campaign_id|
      CampaignsCourses.where(course_id: @course.id, campaign_id: campaign_id).count.positive?
    end
    matching.count == @question_group_campaigns.count
  end
end

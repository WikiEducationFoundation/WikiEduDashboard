# frozen_string_literal: true

class Courses::DeleteFromCampaignController < CoursesController
  include CourseHelper

  def delete_course_from_campaign
    validate
    if params.key?(:campaign)
      remove_course_from_campaign_but_not_deleted
    else 
      remove_and_delete_course_from_campaign
    end
  end

  def validate
    slug = params[:slug].gsub(/\.json$/, '')
    @course = find_course_by_slug(slug)
    raise NotPermittedError unless current_user&.can_edit?(@course)
  end
  
  def remove_and_delete_course_from_campaign
    campaigns_course = find_campaigns_course
    result = campaigns_course.destroy
    message = result ? 'campaign.course_removed_and_deleted' : 'campaign.course_already_removed'
    flash[:notice] = t(message, title: @course.title, campaign_title: params[:campaign_title])
    DeleteCourseWorker.schedule_deletion(course: @course, current_user: current_user)
    redirect_to_campaign_path
  end

  def remove_course_from_campaign_but_not_deleted
    campaigns_course = find_campaigns_course
    result = campaigns_course.destroy
    message = result ? 'campaign.course_removed_but_not_deleted' : 'campaign.course_already_removed'
    flash[:notice] = t(message, title: @course.title, campaign_title: params[:campaign_title])
    redirect_to_campaign_path
  end

  def find_campaigns_course
    CampaignsCourses.find_by(course_id: @course.id, campaign_id: params[:campaign_id])
  end

  def redirect_to_campaign_path
    redirect_to programs_campaign_path(params[:campaign_slug])
  end

end
# frozen_string_literal: true
require "#{Rails.root}/lib/word_count"

#= Presenter for courses / campaign view
class CoursesPresenter
  attr_reader :current_user, :campaign_param

  def initialize(current_user, campaign_param)
    @current_user = current_user
    @campaign_param = campaign_param
  end

  def user_courses
    return unless current_user
    current_user.courses.current_and_future
  end

  def campaign
    return NullCampaign.new if campaign_param == 'none'
    @campaign ||= Campaign.find_by(slug: campaign_param)
    raise NoCampaignError if @campaign.nil? && campaign_param == ENV['default_campaign']
    @campaign
  end

  def campaigns
    Campaign.active
  end

  def courses
    campaign.courses
  end

  def active_courses
    campaign.courses.current_and_future
  end

  def courses_by_recent_edits
    # Sort first by recent edit count, and then by course title
    courses.sort_by { |course| [-course.recent_revision_count, course.title] }
  end

  def active_courses_by_recent_edits
    active_courses.sort_by { |course| [-course.recent_revision_count, course.title] }
  end

  def campaigns_by_num_courses
    # Sort first by number of courses, then by campaign title
    campaigns.sort_by { |campaign| [-campaign.courses.count, campaign.title] }
  end

  def can_create?
    current_user && (current_user.admin? || Features.open_course_creation?)
  end

  def word_count
    WordCount.from_characters courses.sum(:character_sum)
  end

  def course_string_prefix
    Features.default_course_string_prefix
  end

  def uploads_in_use_count
    @uploads_in_use_count ||= courses.sum(:uploads_in_use_count)
    @uploads_in_use_count
  end

  def upload_usage_count
    @upload_usage_count ||= courses.sum(:upload_usages_count)
    @upload_usage_count
  end

  class NoCampaignError < StandardError; end
end

#= Pseudo-Campaign that displays all unsubmitted, non-deleted courses
class NullCampaign
  def title
    I18n.t('courses.unsubmitted')
  end

  def slug
    'none'
  end

  def courses
    Course.unsubmitted.order(created_at: :desc)
  end

  def students_without_nonstudents
    []
  end

  def trained_percent
    0
  end
end

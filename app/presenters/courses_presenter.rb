# frozen_string_literal: true

require "#{Rails.root}/lib/word_count"
require "#{Rails.root}/lib/analytics/histogram_plotter"

#= Presenter for courses / campaign view
class CoursesPresenter
  attr_reader :current_user, :campaign_param

  def initialize(current_user:, campaign_param: nil, courses_list: nil)
    @current_user = current_user
    @campaign_param = campaign_param
    @courses_list = courses_list || campaign&.courses
  end

  def user_courses
    return unless current_user
    current_user.courses.current_and_future
  end

  def campaign
    @campaign ||= Campaign.find_by(slug: campaign_param)
    raise NoCampaignError if @campaign.nil? && campaign_param == ENV['default_campaign']
    @campaign
  end

  def can_remove_course?
    current_user && (current_user.admin? || @campaign.organizers.collect(&:id).include?(current_user.id))
  end

  def campaigns
    Campaign.active
  end

  def courses
    @courses_list
  end

  def active_courses
    courses.current_and_future
  end

  def search_courses(q)
    courses.where('lower(title) like ? OR lower(school) like ? OR lower(term) like ?', "%#{q}%", "%#{q}%", "%#{q}%")
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

  def trained_count
    courses.sum(:trained_count)
  end

  def trained_percent
    return 100 if user_count.zero?
    100 * trained_count.to_f / user_count
  end

  def user_count
    courses.sum(:user_count)
  end

  class NoCampaignError < StandardError; end
end

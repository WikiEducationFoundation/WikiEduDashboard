# frozen_string_literal: true

require_dependency "#{Rails.root}/lib/word_count"
require_dependency "#{Rails.root}/lib/analytics/histogram_plotter"

#= Presenter for courses / campaign view
class CoursesPresenter
  attr_reader :current_user, :campaign_param

  def initialize(current_user:, campaign_param: nil, courses_list: nil)
    @current_user = current_user
    @campaign_param = campaign_param
    @courses_list = courses_list || campaign&.courses&.nonprivate
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
    @can_remove ||= current_user&.admin? || campaign_organizer?
  end

  def campaign_organizer?
    @campaign.organizers.include?(current_user)
  end

  def campaigns
    Campaign.active
  end

  def courses
    @courses_list
  end

  def course_count
    @course_count ||= courses.count
  end

  def active_courses
    courses.current_and_future
  end

  def search_courses(q)
    courses.joins(:instructors).where(
      'lower(title) like ? OR lower(school) like ? ' \
      'OR lower(term) like ? OR lower(username) like ?',
      "%#{q}%", "%#{q}%", "%#{q}%", "%#{q}%"
    ).distinct
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

  COURSE_SUMS_SQL = 'SUM(character_sum), ' \
                    'SUM(article_count), ' \
                    'SUM(new_article_count), ' \
                    'SUM(view_sum), ' \
                    'SUM(user_count), ' \
                    'SUM(references_count)' 
  def course_sums
    @course_sums ||= courses.pluck(Arel.sql(COURSE_SUMS_SQL)).first
  end

  def word_count
    @word_count ||= WordCount.from_characters(course_sums[0] || 0)
  end

  def references_count
    course_sums[5] || 0
  end

  def article_count
    course_sums[1] || 0
  end

  def new_article_count
    course_sums[2] || 0
  end

  def view_sum
    course_sums[3] || 0
  end

  def user_count
    course_sums[4] || 0
  end

  def course_string_prefix
    @campaign&.course_string_prefix || Features.default_course_string_prefix
  end

  def uploads_in_use_count
    @uploads_in_use_count ||= courses.sum(:uploads_in_use_count)
  end

  def upload_usage_count
    @upload_usage_count ||= courses.sum(:upload_usages_count)
  end

  def trained_count
    courses.sum(:trained_count)
  end

  def trained_percent
    return 100 if user_count.zero?
    100 * trained_count.to_f / user_count
  end

  def creation_date
    I18n.localize @campaign.created_at.to_date
  end

  class NoCampaignError < StandardError; end
end

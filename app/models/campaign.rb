# frozen_string_literal: true
require 'csv'
# == Schema Information
#
# Table name: campaigns
#
#  id          :integer          not null, primary key
#  title       :string(255)
#  slug        :string(255)
#  url         :string(255)
#  created_at  :datetime
#  updated_at  :datetime
#  description :text(65535)
#  start       :datetime
#  end         :datetime
#

#= Campaign model
class Campaign < ActiveRecord::Base
  has_many :campaigns_courses, class_name: CampaignsCourses, dependent: :destroy
  has_many :campaigns_users, class_name: CampaignsUsers, dependent: :destroy
  has_many :courses, through: :campaigns_courses
  has_many :students, -> { distinct }, through: :courses
  has_many :instructors, -> { distinct }, through: :courses
  has_many :nonstudents, -> { distinct }, through: :courses
  has_many :organizers, through: :campaigns_users, source: :user
  has_and_belongs_to_many :survey_assignments
  has_many :question_group_conditionals
  has_many :rapidfire_question_groups, through: :question_group_conditionals

  validate :validate_dates

  before_save :set_default_times

  ##########
  # Scopes #
  ##########

  scope :active, -> { where('end > ?', Time.zone.now) }

  ####################
  # Instance methods #
  ####################

  def students_without_nonstudents
    students.where.not(id: nonstudents.pluck(:id))
  end

  def trained_count
    courses.sum(:trained_count)
  end

  def trained_percent
    student_count = students_without_nonstudents.count
    return 100 if student_count.zero?
    100 * trained_count.to_f / student_count
  end

  def users_to_csv(role, opts = {})
    csv_data = []
    courses.each do |course|
      users = course.send(role)
      users.each do |user|
        line = [user.username]
        line << course.slug if opts[:course]
        csv_data << line
      end
    end

    CSV.generate { |csv| csv_data.uniq.each { |line| csv << line } }
  end

  #################
  # Class methods #
  #################

  # Create new campaigns from application.yml entries
  def self.initialize_campaigns
    ENV['campaigns'].split(',').each do |campaign|
      next if Campaign.exists?(slug: campaign)
      Campaign.new(
        'title' => campaign.tr('_', ' ').capitalize,
        'slug' => campaign,
        'url' => ENV['campaign_' + campaign]
      ).save
      Rails.logger.info "Created campaign #{campaign}."
    end
  end

  def self.default_campaign
    find_by(slug: ENV['default_campaign'])
  end

  private

  def validate_dates
    blank_dates = []

    [:start, :end].each do |date_type|
      begin
        # intercept Rails typecasting and add error if given string cannot be parsed into a date
        if value = self.send("#{date_type}_before_type_cast").presence
          self[date_type] = value.is_a?(Date) ? value : DateTime.parse(value)
        else
          blank_dates << date_type
        end
      rescue ArgumentError
        errors.add(date_type, I18n.t('error.invalid_date', key: date_type.capitalize))
      end
    end

    if blank_dates.length == 1
      errors.add(blank_dates.first, I18n.t('error.invalid_date', key: blank_dates.first.capitalize))
    end

    if start && self.end && start > self.end
      errors.add(:start, I18n.t('error.start_date_before_end_date'))
    end
  end

  def set_default_times
    self.start = start.beginning_of_day if start
    self.end = self.end.end_of_day if self.end
  end
end

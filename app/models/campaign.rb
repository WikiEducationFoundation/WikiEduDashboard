# frozen_string_literal: true

require 'csv'
# == Schema Information
#
# Table name: campaigns
#
#  id                   :integer          not null, primary key
#  title                :string(255)
#  slug                 :string(255)
#  url                  :string(255)
#  created_at           :datetime
#  updated_at           :datetime
#  description          :text(65535)
#  start                :datetime
#  end                  :datetime
#  template_description :text(65535)
#  default_course_type  :string(255)
#  default_passcode     :string(255)
#  register_accounts    :boolean          default(FALSE)
#

#= Campaign model
class Campaign < ApplicationRecord
  has_many :campaigns_courses, class_name: 'CampaignsCourses', dependent: :destroy
  has_many :campaigns_users, class_name: 'CampaignsUsers', dependent: :destroy
  has_many :courses, through: :campaigns_courses
  has_many :nonprivate_courses, -> { nonprivate },
           through: :campaigns_courses, source: :course
  has_many :articles_courses, through: :courses
  has_many :articles, -> { distinct }, through: :courses
  has_many :students, -> { distinct }, through: :courses
  has_many :instructors, -> { distinct }, through: :courses
  has_many :nonstudents, -> { distinct }, through: :courses
  has_many :organizers, through: :campaigns_users, source: :user
  has_and_belongs_to_many :survey_assignments
  has_many :question_group_conditionals
  has_many :rapidfire_question_groups, through: :question_group_conditionals
  has_many :requested_accounts, through: :courses
  has_many :alerts, through: :courses
  has_many :public_alerts, through: :nonprivate_courses

  before_validation :set_slug

  validates :title, presence: true
  validates_uniqueness_of :title, message: I18n.t('campaign.already_exists')
  validates_uniqueness_of :slug, message: I18n.t('campaign.already_exists')

  validate :validate_dates

  ALLOWED_TYPES = %w[
    Editathon
    BasicCourse
    ArticleScopedProgram
  ].freeze
  validates :default_course_type, inclusion: { in: ALLOWED_TYPES }, allow_blank: true

  before_save :set_default_times

  ##########
  # Scopes #
  ##########

  scope :active, -> { where('end > ?', Time.zone.now).or(where(end: nil)) }

  ####################
  # Instance methods #
  ####################

  def users_to_csv(role, opts = {})
    csv_data = []
    courses.nonprivate.each do |course|
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

  def self.default_campaign
    find_by(slug: ENV['default_campaign']) || first
  end

  ####################
  # Instance methods #
  ####################

  def course_string_prefix
    return Features.default_course_string_prefix if default_course_type.blank?
    @course_string_prefix ||= default_course_type.constantize.new.string_prefix
  end

  private

  def validate_dates
    # It's fine to have no dates at all.
    return if start.nil? && self.end.nil?

    # If any are present, all must be valid and self-consistent.
    %i[start end].each do |date_type|
      validate_date_attribute(date_type)
    end

    errors.add(:start, I18n.t('error.start_date_before_end_date')) unless valid_start_and_end_dates?
  end

  # Intercept Rails typecasting and add error if given value cannot be parsed into a date.
  def validate_date_attribute(date_type)
    value = send("#{date_type}_before_type_cast")
    self[date_type] = value.is_a?(Date) || value.is_a?(Time) ? value : Time.zone.parse(value)
  rescue ArgumentError, TypeError
    errors.add(date_type, I18n.t('error.invalid_date', key: date_type.capitalize))
  end

  # Start must not be after end.
  def valid_start_and_end_dates?
    return false unless start && self.end
    start <= self.end
  end

  def set_slug
    # Strip everything but unicode letters and digits, and convert spaces to underscores.
    self.slug = title.downcase.gsub(/[^\p{L}0-9 ]/, '').tr(' ', '_') unless slug.present?
  end

  def set_default_times
    self.start = start.beginning_of_day if start
    self.end = self.end.end_of_day if self.end
  end
end

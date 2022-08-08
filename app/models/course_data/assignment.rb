# frozen_string_literal: true

# == Schema Information
#
# Table name: assignments
#
#  id            :integer          not null, primary key
#  created_at    :datetime
#  updated_at    :datetime
#  user_id       :integer
#  course_id     :integer
#  article_id    :integer
#  article_title :string(255)
#  role          :integer
#  wiki_id       :integer
#  sandbox_url   :text(65535)
#

require_dependency "#{Rails.root}/lib/article_utils"
require_dependency "#{Rails.root}/lib/assignment_pipeline"

#= Assignment model
class Assignment < ApplicationRecord
  include MediawikiUrlHelper

  belongs_to :user
  belongs_to :course
  belongs_to :article
  belongs_to :wiki
  has_many :assignment_suggestions, dependent: :destroy

  # The uniqueness constraint for assignments is done with a validation instead
  # of a unique index so that :article_title is case-sensitive.
  validates_uniqueness_of :article_title, scope: %i[course_id user_id role wiki_id],
                                          case_sensitive: true

  INVALID_CHARACTER_MATCHER = /\A[^{}\[\]\t<>]+\Z/
  validates :article_title, format: { with: INVALID_CHARACTER_MATCHER }
  LEADING_COLON_MATCHER = /\A[^:]/
  validates :article_title, format: { with: LEADING_COLON_MATCHER }
  SPECIAL_PAGE_MATCHER = /\A(?!Special:).*/
  validates :article_title, format: { with: SPECIAL_PAGE_MATCHER }
  scope :assigned, -> { where(role: 0) }
  scope :reviewing, -> { where(role: 1) }

  before_validation :set_defaults_and_normalize
  before_save :set_sandbox_url

  serialize :flags, Hash

  delegate :status, to: :assignment_pipeline
  delegate :update_status, to: :assignment_pipeline
  delegate :all_statuses, to: :assignment_pipeline

  #############
  # CONSTANTS #
  #############
  module Roles
    ASSIGNED_ROLE  = 0
    REVIEWING_ROLE = 1
  end

  ROLE_NAMES = {
    Roles::ASSIGNED_ROLE => 'Editing',
    Roles::REVIEWING_ROLE => 'Reviewing'
  }.freeze

  ####################
  # Instance methods #
  ####################
  def article_url
    "#{wiki.base_url}/wiki/#{url_encoded_mediawiki_title article_title}"
  end

  # A sibling assignment is an assignment for a different user,
  # but for the same Article in the same course.
  def sibling_assignments
    Assignment
      .where(course_id:, article_id:)
      .where.not(id:)
      .where.not(user: user_id)
  end

  def editing?
    role == Roles::ASSIGNED_ROLE
  end

  private

  def assignment_pipeline
    @pipeline ||= AssignmentPipeline.new(assignment: self)
  end

  def set_defaults_and_normalize
    self.wiki_id ||= course.home_wiki.id
    return if article_title.nil?
    self.article_title = ArticleUtils.format_article_title(article_title, wiki)
  end

  def set_sandbox_url
    return unless user
    # If the sandbox already exists, use that URL instead
    existing = Assignment.where(course:, article_title:, wiki:)
                         .where.not(user:).first
    if existing
      self.sandbox_url = existing.sandbox_url
    else
      language = wiki.language || 'www'
      project = wiki.project || 'wikipedia'
      base_url = "https://#{language}.#{project}.org/wiki"
      encoded_title = url_encoded_mediawiki_title(article_title)
      self.sandbox_url = "#{base_url}/User:#{user.username}/#{encoded_title}"
    end
  end
end

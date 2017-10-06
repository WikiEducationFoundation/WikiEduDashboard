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
#

require "#{Rails.root}/lib/article_utils"

#= Assignment model
class Assignment < ActiveRecord::Base
  belongs_to :user
  belongs_to :course
  belongs_to :article
  belongs_to :wiki
  has_many :assignment_suggestions, dependent: :destroy

  # The uniqueness constraint for assignments is done with a validation instead
  # of a unique index so that :article_title is case-sensitive.
  validates_uniqueness_of :article_title, scope: %i[course_id user_id role wiki_id]

  scope :assigned, -> { where(role: 0) }
  scope :reviewing, -> { where(role: 1) }

  before_validation :set_defaults_and_normalize

  #############
  # CONSTANTS #
  #############
  module Roles
    ASSIGNED_ROLE  = 0
    REVIEWING_ROLE = 1
  end

  ####################
  # Instance methods #
  ####################
  def page_url
    "#{wiki.base_url}/wiki/#{article_title}"
  end

  # A sibling assignment is an assignment for a different user,
  # but for the same Article in the same course.
  def sibling_assignments
    Assignment
      .where(course_id: course_id, article_id: article_id)
      .where.not(id: id)
      .where.not(user: user_id)
  end

  private

  def set_defaults_and_normalize
    self.article_title = ArticleUtils.format_article_title(article_title) unless article_title.nil?
    self.wiki_id ||= course.home_wiki.id
  end
end

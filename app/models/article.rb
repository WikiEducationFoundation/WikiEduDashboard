# frozen_string_literal: true

# == Schema Information
#
# Table name: articles
#
#  id                       :integer          not null, primary key
#  title                    :string(255)
#  updated_at               :datetime
#  created_at               :datetime
#  views_updated_at         :date
#  namespace                :integer
#  rating                   :string(255)
#  rating_updated_at        :datetime
#  deleted                  :boolean          default(FALSE)
#  language                 :string(10)
#  average_views            :float(24)
#  average_views_updated_at :date
#  wiki_id                  :integer
#  mw_page_id               :integer
#

require "#{Rails.root}/lib/utils"
require "#{Rails.root}/lib/importers/view_importer"
require "#{Rails.root}/lib/importers/article_importer"

#= Article model
class Article < ActiveRecord::Base
  has_many :revisions
  has_many :editors, through: :revisions, source: :user
  has_many :articles_courses, class_name: 'ArticlesCourses'
  has_many :courses, -> { distinct }, through: :articles_courses
  has_many :assignments
  belongs_to :wiki

  alias_attribute :page_id, :mw_page_id

  scope :live, -> { where(deleted: false) }
  scope :current, -> { joins(:courses).merge(Course.current).distinct }
  scope :ready_for_update, -> { joins(:courses).merge(Course.ready_for_update).distinct }
  scope :namespace, ->(ns) { where(namespace: ns) }
  scope :assigned, -> { joins(:assignments).distinct }

  validates :title, presence: true
  validates :wiki_id, presence: true
  validates :mw_page_id, presence: true

  before_validation :set_defaults_and_normalize

  ####################
  # CONSTANTS        #
  ####################
  module Namespaces
    MAINSPACE      = 0
    TALK           = 1
    USER           = 2
    USER_TALK      = 3
    WIKIPEDIA      = 4
    WIKIPEDIA_TALK = 5
    TEMPLATE       = 10
    TEMPLATE_TALK  = 11
    DRAFT          = 118
    DRAFT_TALK     = 119
  end

  NS_PREFIX = {
    Namespaces::MAINSPACE => '',
    Namespaces::TALK => 'Talk:',
    Namespaces::USER => 'User:',
    Namespaces::USER_TALK => 'User_talk:',
    Namespaces::WIKIPEDIA => 'Wikipedia:',
    Namespaces::WIKIPEDIA_TALK => 'Wikipedia_talk:',
    Namespaces::TEMPLATE => 'Template:',
    Namespaces::TEMPLATE_TALK => 'Template_talk:',
    Namespaces::DRAFT => 'Draft:',
    Namespaces::DRAFT_TALK => 'Draft_talk:'
  }.freeze

  ####################
  # Instance methods #
  ####################
  def url
    "#{wiki.base_url}/wiki/#{namespace_prefix}#{title}"
  end

  def full_title
    title = self.title.tr('_', ' ')
    "#{namespace_prefix}#{title}"
  end

  def escaped_full_title
    "#{namespace_prefix}#{title}"
  end

  def namespace_prefix
    NS_PREFIX[namespace]
  end

  #################
  # Class methods #
  #################
  def self.update_all_caches(articles=nil)
    Utils.run_on_all(Article, :update_cache, articles)
  end

  private

  def set_defaults_and_normalize
    # Always save titles with underscores instead of spaces, since that's the way
    # they are in the MediaWiki database.
    self.title = title.tr(' ', '_') unless title.nil?
  end
end

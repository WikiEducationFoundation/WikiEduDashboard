# frozen_string_literal: true
# == Schema Information
#
# Table name: articles
#
#  id                       :integer          not null, primary key
#  title                    :string(255)
#  views                    :integer          default(0)
#  created_at               :datetime
#  updated_at               :datetime
#  character_sum            :integer          default(0)
#  revision_count           :integer          default(0)
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
  has_many :articles_courses, class_name: ArticlesCourses
  has_many :courses, -> { distinct }, through: :articles_courses
  has_many :assignments
  belongs_to :wiki

  alias_attribute :page_id, :mw_page_id

  scope :live, -> { where(deleted: false) }
  scope :current, -> { joins(:courses).merge(Course.current).distinct }
  scope :namespace, -> (ns) { where(namespace: ns) }

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

  ####################
  # Instance methods #
  ####################
  def update(data={}, save=true)
    self.attributes = data
    self.views = if revisions.count.positive?
                   revisions.order('date ASC').first.views || 0
                 else
                   0
                 end
    self.save if save
  end

  #################
  # Cache methods #
  #################
  def character_sum
    update_cache unless self[:character_sum]
    self[:character_sum]
  end

  def revision_count
    self[:revision_count] || revisions.size
  end

  def update_cache
    # Do not consider revisions with negative byte changes
    self.character_sum = revisions.where('characters >= 0').sum(:characters)
    self.revision_count = revisions.size
    save
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

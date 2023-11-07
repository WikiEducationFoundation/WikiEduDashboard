# frozen_string_literal: true

# == Schema Information
#
# Table name: articles
#
#  id                       :integer          not null, primary key
#  title                    :string(255)
#  created_at               :datetime
#  updated_at               :datetime
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
#  index_hash               :string(255)
#

require_dependency Rails.root.join('lib/importers/article_importer')

#= Article model
class Article < ApplicationRecord
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
  scope :sandbox, -> { where(namespace: Namespaces::USER) }
  scope :assigned, -> { joins(:assignments).distinct }

  validates :title, presence: true
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
    PROJECT        = 4
    PROJECT_TALK   = 5
    FILE           = 6
    TEMPLATE       = 10
    TEMPLATE_TALK  = 11
    PAGE           = 104
    BOOK           = 108
    WIKIJUNIOR     = 110
    TRANSLATION    = 114
    DRAFT          = 118
    DRAFT_TALK     = 119
    PROPERTY       = 120
    QUERY          = 122
    LEXEME         = 146
  end

  NS_PREFIX = {
    Namespaces::MAINSPACE => '',
    Namespaces::TALK => 'Talk:',
    Namespaces::USER => 'User:',
    Namespaces::USER_TALK => 'User_talk:',
    Namespaces::TEMPLATE => 'Template:',
    Namespaces::TEMPLATE_TALK => 'Template_talk:',
    Namespaces::DRAFT => 'Draft:',
    Namespaces::DRAFT_TALK => 'Draft_talk:',
    Namespaces::PROPERTY => 'Property:',
    Namespaces::QUERY => 'Query:',
    Namespaces::LEXEME => 'Lexeme:',
    Namespaces::FILE => 'File:',
    Namespaces::PAGE => 'Page:',
    Namespaces::BOOK => 'Book:',
    Namespaces::WIKIJUNIOR => 'Wikijunior:',
    Namespaces::TRANSLATION => 'Translation:',
    # The following namespace index are spread over
    # several wikis and needs to be additionally
    # namespaced via project
    4 => {
      'wikipedia' => 'Wikipedia:',
      'wiktionary' => 'Wiktionary:',
      'wikisource' => 'Wikisource:',
      'wikiversity' => 'Wikiversity:',
      'wikidata' => 'Wikidata:',
      'wikiquote' => 'Wikiquote:',
      'wikivoyage' => 'Wikivoyage:',
      'wikinews' => 'Wikinews:',
      'wikibooks' => 'Wikibooks:',
      'commons' => 'Commons:',
      'incubator' => 'Incubator:'
    },
    5 => {
      'wikipedia' => 'Wikipedia_talk:',
      'wiktionary' => 'Wiktionary_talk:',
      'wikisource' => 'Wikisource_talk:',
      'wikiversity' => 'Wikiversity_talk:',
      'wikidata' => 'Wikidata_talk:',
      'wikiquote' => 'Wikiquote_talk:',
      'wikivoyage' => 'Wikivoyage_talk:',
      'wikinews' => 'Wikinews_talk:',
      'wikibooks' => 'Wikibooks_talk:',
      'commons' => 'Commons_talk:',
      'incubator' => 'Incubator_talk:'
    },
    100 => {
      'wiktionary' => 'Appendix:',
      'wikisource' => 'Portal:',
      'wikiversity' => 'School:'
    },
    102 => {
      'wikisource' => 'Author:',
      'wikibooks' => 'Cookbook:',
      'wikiversity' => 'Portal:'
    },
    106 => {
      'wiktionary' => 'Rhymes:',
      'wikisource' => 'Index:',
      'wikiversity' => 'Collection:'
    }
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
    prefix = NS_PREFIX[namespace]
    return prefix if prefix.is_a?(String)
    prefix[wiki.project == 'wikimedia' ? wiki.language : wiki.project]
  end

  def fetch_page_content
    WikiApi.new(wiki).get_page_content(escaped_full_title)
  end

  private

  def set_defaults_and_normalize
    # Always save titles with underscores instead of spaces, since that's the way
    # they are in the MediaWiki database.
    self.title = title.tr(' ', '_') unless title.nil?
  end
end

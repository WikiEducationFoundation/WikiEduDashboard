# frozen_string_literal: true
# == Schema Information
#
# Table name: categories
#
#  id             :bigint           not null, primary key
#  wiki_id        :integer
#  article_titles :text(16777215)
#  name           :string(255)
#  depth          :integer          default(0)
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  source         :string(255)      default("category")
#

require_dependency "#{Rails.root}/lib/importers/category_importer"
require_dependency "#{Rails.root}/lib/importers/transclusion_importer"
require_dependency "#{Rails.root}/lib/article_utils"
require_dependency "#{Rails.root}/lib/petscan_api.rb"
require_dependency "#{Rails.root}/lib/pagepile_api.rb"

class Category < ApplicationRecord
  include EncodingHelper

  belongs_to :wiki
  has_many :categories_courses, class_name: 'CategoriesCourses', dependent: :destroy
  has_many :courses, through: :categories_courses

  serialize :article_titles, Array

  validates :name, presence: true, length: { minimum: 1 }
  validates :name, numericality: { only_integer: true }, on: :create,
                   if: -> { source == 'psid' || source == 'pileid' }

  validates :depth, numericality: {
    only_integer: true,
    greater_than_or_equal_to: 0,
    less_than_or_equal_to: 3
  }

  def self.get_or_create(wiki:, name:, depth:, source:)
    if source == 'pileid'
      get_or_create_by_pileid(wiki:, name:, depth:, source:)
    else
      find_or_create_by(wiki:, name:, depth:, source:)
    end
  end

  def self.get_or_create_by_pileid(wiki:, name:, depth:, source:)
    # For pagepile records, the name should be unique. Depth
    # is not applicable, and wiki gets set via PagePileApi if it
    # doesn't match.
    record = find_by(source:, name:)
    return record || create(wiki:, name:, depth:, source:)
  end

  def self.refresh_categories_for(course, update_service: nil)
    # Updating categories only if they were last updated since
    # more than a day, or those which are newly created
    course.categories
          .where('categories.updated_at < ? OR categories.created_at = categories.updated_at',
                 1.day.ago)
          .find_each do |category|
            category.refresh_titles(update_service:)
          end
  end

  def refresh_titles(update_service: nil)
    self.article_titles = title_list_from_wiki(update_service:).map do |title|
      sanitize_4_byte_string ArticleUtils.format_article_title(title)
    end
    save
    # rubocop:disable Rails/SkipsModelValidations
    # Using touch to update the timestamps even when there is actually no
    # updation (SQL update query) in the category
    touch(:updated_at)
    # rubocop:enable Rails/SkipsModelValidations
  end

  def article_ids
    @article_ids ||= Article.where(namespace: 0, wiki_id:, title: article_titles).pluck(:id)
  end

  def name_with_prefix
    "#{source.capitalize}:#{name}"
  end

  private

  def title_list_from_wiki(update_service: nil)
    case source
    when 'category'
      CategoryImporter.new(wiki, update_service:)
                      .mainspace_page_titles_for_category(name_with_prefix, depth)
    when 'psid'
      PetScanApi.new.page_titles_for_psid(name, update_service:)
    when 'pileid'
      PagePileApi.new(self).page_titles_for_pileid(update_service:)
    when 'template'
      TransclusionImporter.new(self, update_service:).transcluded_titles
    end
  end
end

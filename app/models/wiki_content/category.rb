# frozen_string_literal: true
# == Schema Information
#
# Table name: categories
#
#  id             :bigint(8)        not null, primary key
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
  belongs_to :wiki
  has_many :categories_courses, class_name: 'CategoriesCourses', dependent: :destroy
  has_many :courses, through: :categories_courses

  serialize :article_titles, Array

  def self.refresh_categories_for(course)
    # Updating categories only if they were last updated since
    # more than a day, or those which are newly created
    course.categories
          .where('categories.updated_at < ? OR categories.created_at = categories.updated_at',
                 1.day.ago)
          .find_each(&:refresh_titles)
  end

  def refresh_titles
    self.article_titles = title_list_from_wiki.map do |title|
      ArticleUtils.format_article_title(title)
    end
    save
    # Using touch to update the timestamps even when there is actually no
    # updation (SQL update query) in the category
    touch(:updated_at)
  end

  def article_ids
    @article_ids ||= Article.where(namespace: 0, wiki_id: wiki_id, title: article_titles).pluck(:id)
  end

  def name_with_prefix
    "#{source.capitalize}:#{name}"
  end

  private

  def title_list_from_wiki
    case source
    when 'category'
      CategoryImporter.new(wiki).page_titles_for_category(name_with_prefix, depth)
    when 'psid'
      PetScanApi.new.page_titles_for_psid(name)
    when 'pileid'
      PagePileApi.new(self).page_titles_for_pileid
    when 'template'
      TransclusionImporter.new(self).transcluded_titles
    end
  end
end

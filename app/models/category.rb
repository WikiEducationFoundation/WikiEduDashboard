# frozen_string_literal: true
# == Schema Information
#
# Table name: categories
#
#  id             :integer          not null, primary key
#  wiki_id        :integer
#  article_titles :text(16777215)
#  name           :string(255)
#  depth          :integer          default(0)
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#

require "#{Rails.root}/lib/importers/category_importer"
require "#{Rails.root}/lib/article_utils"

class Category < ApplicationRecord
  belongs_to :wiki
  has_many :categories_courses, class_name: 'CategoriesCourses', dependent: :destroy
  has_many :courses, through: :categories_courses

  serialize :article_titles, Array

  def self.refresh_categories_for(courses)
    CategoriesCourses.where(course: courses).each do |category_course|
      category_course.category.refresh_titles
    end
  end

  def refresh_titles
    titles = CategoryImporter.new(wiki).page_titles_for_category(name_with_prefix, depth)
    self.article_titles = titles.map { |title| ArticleUtils.format_article_title(title) }
    save
  end

  def name_with_prefix
    "Category:#{name}"
  end

  def article_ids
    Article.where(namespace: 0, wiki_id: wiki_id, title: article_titles).pluck(:id)
  end
end

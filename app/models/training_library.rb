# frozen_string_literal: true
# == Schema Information
#
# Table name: training_libraries
#
#  id                 :bigint(8)        not null, primary key
#  name               :string(255)
#  wiki_page          :string(255)
#  introduction       :text(65535)
#  categories         :text(16777215)
#  translations       :text(16777215)
#  exclude_from_index :boolean          default: false
#  slug               :string(255)
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#

require_dependency "#{Rails.root}/lib/training/training_base"

#= Class representing an individual training module
class TrainingLibrary < ApplicationRecord
  serialize :categories, Array
  serialize :translations, Hash

  validates :slug, uniqueness: true

  def self.path_to_yaml
    "#{base_path}/libraries/*.yml"
  end

  def self.wiki_base_page
    ENV['training_libraries_wiki_page']
  end

  def self.trim_id_from_filename
    false
  end

  def self.load
    TrainingBase.load(content_class: self)
  end

  def self.base_path
    TrainingBase.base_path
  end

  def self.inflate(content, slug, wiki_page = nil) # rubocop:disable Metrics/MethodLength
    training_library = TrainingLibrary.find_or_initialize_by(id: content['id'])
    training_library.slug = slug
    training_library.name = content['name'] || content[:name]
    training_library.description = content['description'] || content[:description]
    training_library.translations = content['translations']
    training_library.wiki_page = wiki_page
    training_library.categories = content['categories']
    training_library.exclude_from_index = content['exclude_from_index']
    training_library
  end

  ####################
  # Instance methods #
  ####################

  def translated_name
    translated(:name) || name
  end

  def translated_introduction
    translated(:introduction) || introduction
  end

  def translated(key)
    translations.dig(I18n.locale.to_s, key)
  end
end

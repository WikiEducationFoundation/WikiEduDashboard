# frozen_string_literal: true

require "#{Rails.root}/lib/training/training_base"

class TrainingLibrary < TrainingBase
  attr_accessor :name, :modules, :introduction, :categories, :id
  alias raw_modules modules
  alias raw_categories categories

  #################
  # Class methods #
  #################
  def self.cache_key
    'libraries'
  end

  def self.path_to_yaml
    "#{base_path}/libraries/*.yml"
  end

  def self.wiki_base_page
    ENV['training_libraries_wiki_page']
  end

  def self.trim_id_from_filename
    false
  end
  ####################
  # Instance methods #
  ####################

  # transform categories hash into nested objects for view simplicity
  def categories
    raw_categories.to_hashugar
  end

  def valid?
    required_attributes = [id, name, slug, introduction, categories]
    required_attributes.all?
  end
end

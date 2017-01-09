# frozen_string_literal: true
require "#{Rails.root}/lib/training/training_base"

class TrainingLibrary < TrainingBase
  attr_accessor :name, :modules, :introduction, :categories, :id
  alias raw_modules modules
  alias raw_categories categories

  #################
  # Class methods #
  #################
  def self.load(load_all: true, **)
    super path_to_yaml: "#{base_path}/libraries/*.yml",
          wiki_base_page: 'User:Ragesoss/library_test',
          cache_key: 'libraries',
          load_all: load_all
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

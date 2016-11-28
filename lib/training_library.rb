# frozen_string_literal: true
require 'from_yaml'

class TrainingLibrary < FromYaml
  attr_accessor :name, :modules, :introduction, :categories, :id
  alias raw_modules modules
  alias raw_categories categories

  #################
  # Class methods #
  #################
  def self.load(*)
    super path_to_yaml: "#{base_path}/libraries/*.yml",
          cache_key: 'libraries'
  end

  ####################
  # Instance methods #
  ####################

  # transform categories hash into nested objects for view simplicity
  def categories
    raw_categories.to_hashugar
  end
end

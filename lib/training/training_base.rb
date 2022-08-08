# frozen_string_literal: true

require_dependency "#{Rails.root}/lib/training/yaml_training_loader"
require_dependency "#{Rails.root}/lib/training/wiki_training_loader"

class TrainingBase
  # cattr_accessor would be cause children's implementations to conflict w/each other
  class << self
    attr_accessor :path_to_yaml
  end

  #################
  # Class methods #
  #################

  # called for each child class in initializers/training_content.rb
  def self.load(slug_list: nil, content_class: self)
    loader = training_loader_class.new(content_class:, slug_list:)
    loader.load_content
  end

  # Called during manual :training_reload action.
  # This should regenerate all training content from yml files and/or wiki.
  def self.load_all
    TrainingLibrary.load
    TrainingModule.load
    if Features.wiki_trainings?
      TrainingModule.all.each { |tm| TrainingSlide.load(slug_list: tm.slide_slugs) }
    else
      TrainingSlide.load
    end
  end

  def self.base_path
    if ENV['training_path']
      "#{Rails.root}/#{ENV['training_path']}"
    else
      "#{Rails.root}/training_content/wiki_ed"
    end
  end

  def self.training_loader_class
    Features.wiki_trainings? ? WikiTrainingLoader : YamlTrainingLoader
  end

  class DuplicateSlugError < StandardError
  end
end

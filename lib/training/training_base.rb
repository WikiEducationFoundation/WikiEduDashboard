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
    if Features.wiki_trainings?
      WikiTrainingLoaderWorker.new.perform(content_class, slug_list)
    else
      YamlTrainingLoader.load(content_class, slug_list)
    end
  end

  def self.base_path
    if ENV['training_path']
      "#{Rails.root}/#{ENV['training_path']}"
    else
      "#{Rails.root}/training_content/wiki_ed"
    end
  end

  class DuplicateSlugError < StandardError
  end
end

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
  def self.load_from_wiki(slug_list: nil, content_class: self)
    WikiTrainingLoaderWorker.new.perform(content_class, slug_list)
  end

  def self.load_from_yaml(slug_list: nil, content_class: self)
    YamlTrainingLoader.new(content_class:, slug_list:).load_content
  end

  def self.base_path
    if ENV['training_path']
      "#{Rails.root}/#{ENV['training_path']}"
    else
      "#{Rails.root}/training_content/wiki_ed"
    end
  end

  def self.update_status_to_scheduled(slug)
    TrainingLibrary.update_all(update_status: 1)
    TrainingModule.update_all(update_status: 1)

    if slug == 'all'
      TrainingSlide.update_all(update_status: 1)
    else
      module_to_update = TrainingModule.where(slug)
      slide_slugs = module_to_update.pluck(:slide_slugs)
      TrainingSlide.where(slug: slide_slugs).update_all(update_status: 1)
    end
  end

  def self.error_message
    library_record_with_error = TrainingLibrary.find_by(update_status: 1)
    module_record_with_error = TrainingModule.find_by(update_status: 1)
    slide_record_with_error = TrainingSlide.find_by(update_status: 1)

    library_record_with_error&.update_error

    module_record_with_error&.update_error

    slide_record_with_error&.update_error
  end

  def self.check_errors
    exists(update_status: 2)
  end

  def self.update_error(message, content_class)
    content_class.update_all(update_status: 2, update_error: message)
  end

  class DuplicateSlugError < StandardError
  end
end

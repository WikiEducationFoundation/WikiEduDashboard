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

  def self.update_status_to_scheduled(slug: nil)
    TrainingLibrary.update_all(update_status: 1)
    TrainingModule.update_all(update_status: 1)

    if slug
      module_to_update = TrainingModule.where(slug:)
      slide_slugs = modules_to_update.pluck(:slide_slugs)
      TrainingSlide.where(slug: slide_slugs).update_all(update_status: 1)
    else
      TrainingSlide.update_all(update_status: 1)
    end
  end

  def self.update_status_to_started(wiki_page)
    find_by(wiki_page:).update(update_status: 2)
  end

  def self.update_status_to_complete
    find_by(wiki_page:).update(update_status: 0)
  end

  def self.find_not_complete
    exists(update_status: 2)
  end

  def self.update_error(message, content_class, slug)
    content_class.find_by(slug:).update(update_error: message)
  end

  def self.update_error_content_class(message, content_class)
    content_class.update_all(update_error: message)
  end

  class DuplicateSlugError < StandardError
  end
end

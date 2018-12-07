# frozen_string_literal: true

require_dependency "#{Rails.root}/lib/training/yaml_training_loader"
require_dependency "#{Rails.root}/lib/training/wiki_training_loader"

class TrainingBase
  # cattr_accessor would be cause children's implementations to conflict w/each other
  class << self
    attr_accessor :path_to_yaml
  end

  attr_accessor :slug, :id, :wiki_page

  #################
  # Class methods #
  #################

  # called for each child class in initializers/training_content.rb
  def self.load(slug_list: nil, content_class: self)
    loader = training_loader_class.new(content_class: content_class, slug_list: slug_list)
    @all = loader.load_content
    return if content_class.superclass.name == 'ApplicationRecord'

    check_for_duplicate_slugs
    check_for_duplicate_ids
    Rails.cache.write cache_key, @all

    @all
  end

  # Called during manual :training_reload action.
  # This should regenerate all training content from yml files and/or wiki.
  def self.load_all
    TrainingLibrary.flush
    if Features.wiki_trainings?
      TrainingModule.load
      TrainingModule.all.each { |tm| TrainingSlide.load(slug_list: tm.slide_slugs) }
      TrainingLibrary.load
    else
      TrainingLibrary.load
      TrainingModule.load
      TrainingSlide.load
    end
  end

  # Use class instance variable @all to store all training content in memory.
  # This will normally persist until flushed.
  def self.all
    @all ||= load_from_cache_or_rebuild
  end

  def self.load_from_cache_or_rebuild
    Rails.cache.read(cache_key) || load
  end

  # Clears both the class instance variable and the cache for the child class.
  def self.flush
    Rails.cache.delete(cache_key)
    @all = nil
  end

  def self.find_by(opts)
    all.detect { |obj| obj.slug == opts[:slug] }
  end

  def self.check_for_duplicate_slugs
    all_slugs = all.map(&:slug)
    duplicate_slug = all_slugs.detect { |slug| all_slugs.count(slug) > 1 }
    return if duplicate_slug.nil?
    type = all[0].class
    raise DuplicateSlugError, "duplicate #{type} slug detected: #{duplicate_slug}"
  end

  def self.check_for_duplicate_ids
    all_ids = all.map(&:id)
    duplicate_id = all_ids.detect { |id| all_ids.count(id) > 1 }
    return if duplicate_id.nil?
    type = all[0].class
    collisions = all.select { |training| training.id == duplicate_id }
    slugs = collisions.map(&:slug)
    raise DuplicateIdError, "Duplicate #{type} id detected: #{duplicate_id}. Slugs: #{slugs}"
  end

  def self.base_path
    if ENV['training_path']
      "#{Rails.root}/#{ENV['training_path']}"
    else
      "#{Rails.root}/training_content/wiki_ed"
    end
  end

  # called for each training unit in TrainingLoader
  def self.inflate(content, slug, wiki_page = nil)
    new(content.to_hashugar, slug, wiki_page)
  end

  def self.training_loader_class
    Features.wiki_trainings? ? WikiTrainingLoader : YamlTrainingLoader
  end

  class DuplicateSlugError < StandardError
  end

  class DuplicateIdError < StandardError
  end

  ####################
  # Instance methods #
  ####################

  def initialize(content, slug, wiki_page)
    self.slug = slug
    content.each do |key, value|
      instance_variable_set("@#{key}", value)
    end
    self.wiki_page = wiki_page
  rescue StandardError => e
    puts "There's a problem with file '#{slug}'"
    raise e
  end

  # Implemented by each child class
  def self.cache_key
    raise NotImplementedError
  end

  def valid?
    raise NotImplementedError
  end
end

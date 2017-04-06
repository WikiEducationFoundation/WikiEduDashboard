# frozen_string_literal: true
require "#{Rails.root}/lib/training/training_loader"

class TrainingBase
  # cattr_accessor would be cause children's implementations to conflict w/each other
  class << self
    attr_accessor :path_to_yaml
  end

  attr_accessor :slug, :id

  #################
  # Class methods #
  #################

  # called for each child class in initializers/training_content.rb
  def self.load(path_to_yaml:, wiki_base_page:,
                trim_id_from_filename: false)
    self.path_to_yaml = path_to_yaml

    loader = TrainingLoader.new(content_class: self, path_to_yaml: path_to_yaml,
                                wiki_base_page: wiki_base_page,
                                trim_id_from_filename: trim_id_from_filename)
    loader.load_content

    check_for_duplicate_slugs
    check_for_duplicate_ids
  end

  # Called during initialization, and also via manual :training_reload action.
  # This should regenerate all training content from yml files and/or wiki.
  def self.load_all
    TrainingLibrary.flush
    TrainingModule.flush
    TrainingSlide.flush
    TrainingLibrary.load
    TrainingModule.load
    TrainingSlide.load
  end

  # Use class instance variable @all to store all training content in memory.
  # This will normally persist until flushed or until the app is restarted.
  def self.all
    @all ||= all_from_cache
  end

  # The Rails cache is persistent, but gets overwritten via load_all (which runs
  # in an intializer)
  def self.all_from_cache
    cached = Rails.cache.read(cache_key)
    if cached.nil?
      load(path_to_yaml: path_to_yaml)
      cached = Rails.cache.read(cache_key)
    end
    cached
  end

  # Clears both the class instance variable and the cache for the child class.
  def self.flush
    Rails.cache.clear(cache_key)
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

  class DuplicateSlugError < StandardError
  end

  class DuplicateIdError < StandardError
  end

  ####################
  # Instance methods #
  ####################

  # called for each training unit in TrainingLoader
  def initialize(content, slug)
    self.slug = slug
    content.each do |key, value|
      instance_variable_set("@#{key}", value)
    end
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

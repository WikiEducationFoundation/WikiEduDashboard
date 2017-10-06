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
  def self.load(slug_whitelist: nil)
    loader = TrainingLoader.new(content_class: self, slug_whitelist: slug_whitelist)

    @all = if slug_whitelist
             merge_content loader.load_content
           else
             loader.load_content
           end

    check_for_duplicate_slugs
    check_for_duplicate_ids
    Rails.cache.write cache_key, @all

    @all
  end

  def self.merge_content(updated_content)
    new_slugs = updated_content.map(&:slug)
    # @all may be nil or an array of training objects
    old_without_new = Array(@all).reject do |training_unit|
      new_slugs.include? training_unit.slug
    end
    old_without_new + updated_content
  end

  # Called during manual :training_reload action.
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

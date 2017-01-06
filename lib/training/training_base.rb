# frozen_string_literal: true
require "#{Rails.root}/lib/training/training_loader"

class TrainingBase
  # cattr_accessor would be cause children's implementations to conflict w/each other
  class << self
    attr_accessor :cache_key, :path_to_yaml
  end

  attr_accessor :slug, :id

  #################
  # Class methods #
  #################

  # called for each child class in initializers/training_content.rb
  def self.load(cache_key:, path_to_yaml:, wiki_base_page:,
                trim_id_from_filename: false, load_all: true)
    self.cache_key = cache_key
    self.path_to_yaml = path_to_yaml

    loader = TrainingLoader.new(content_class: self, cache_key: cache_key,
                                path_to_yaml: path_to_yaml, wiki_base_page: wiki_base_page,
                                trim_id_from_filename: trim_id_from_filename)

    load_all ? loader.load_all : loader.load

    check_for_duplicate_slugs
    check_for_duplicate_ids
  end

  def self.load_all
    TrainingLibrary.load(load_all: true)
    TrainingModule.load(load_all: true)
    TrainingSlide.load(load_all: true)
  end

  def self.all
    load_all if Rails.cache.read(cache_key).nil?
    Rails.cache.read(cache_key)
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
    raise DuplicateIdError, "duplicate #{type} id detected: #{duplicate_id}"
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
  def valid?
    raise NotImplementedError
  end
end

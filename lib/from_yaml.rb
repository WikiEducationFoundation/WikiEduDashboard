# frozen_string_literal: true
class FromYaml
  # cattr_accessor would be cause children's implementations to conflict w/each other
  class << self
    attr_accessor :cache_key, :path_to_yaml, :wiki_root_page
  end

  attr_accessor :slug, :id

  #################
  # Class methods #
  #################

  # called from the initializers/training_content.rb
  def self.load(args)
    collection = []

    self.cache_key = args[:cache_key]
    self.path_to_yaml = args[:path_to_yaml]
    self.wiki_root_page = 'User:Ragesoss/data.json'

    Dir.glob(path_to_yaml) do |yaml_file|
      collection << new_from_file(yaml_file, args[:trim_id_from_filename])
    end
    wiki_source_pages.each do |wiki_page|
      collection << new_from_wiki_page(wiki_page)
    end

    Rails.cache.write args[:cache_key], collection
    check_for_duplicate_slugs
    check_for_duplicate_ids
  end

  def self.wiki_source_pages
    [wiki_root_page]
  end

  def self.new_from_wiki_page(wiki_page)
    wikitext = WikiApi.new(MetaWiki.new).get_page_content(wiki_page)
    content = JSON.parse(wikitext).to_hashugar
    new(content, content.slug)
  end

  def self.new_from_file(yaml_file, trim_id)
    slug = File.basename(yaml_file, '.yml')
    slug.gsub!(/^[0-9]+-/, '') if trim_id

    content = YAML.load_file(yaml_file).to_hashugar
    new(content, slug)
  end

  def self.all
    if Rails.cache.read(cache_key).nil?
      load(cache_key: cache_key, path_to_yaml: path_to_yaml)
    end
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

  # called in load
  def initialize(content, slug)
    self.slug = slug
    content.each do |key, value|
      instance_variable_set("@#{key}", value)
    end
  rescue StandardError => e
    puts "There's a problem with file '#{slug}'"
    raise e
  end
end

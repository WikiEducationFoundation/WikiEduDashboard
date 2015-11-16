class FromYaml

  # cattr_accessor would be cause children's implementations to conflict w/each other
  class << self
    attr_accessor :cache_key, :path_to_yaml
  end

  attr_accessor :slug

  #################
  # Class methods #
  #################

  # called from the initializers/training_content.rb
  def self.load(args)
    collection = []

    self.cache_key = args[:cache_key]
    self.path_to_yaml = args[:path_to_yaml]

    Dir.glob(self.path_to_yaml) do |yaml_file|
      slug = File.basename(yaml_file, '.yml')
      if args[:trim_id_from_filename]
        slug.gsub!(/^[0-9]+-/, '')
      end
      content = YAML.load_file(yaml_file).to_hashugar
      collection << self.new(content, slug)
    end
    Rails.cache.write args[:cache_key], collection
  end

  def self.all
    if Rails.cache.read(self.cache_key).nil?
      self.load(cache_key: self.cache_key, path_to_yaml: self.path_to_yaml)
    end
    Rails.cache.read(self.cache_key)
  end

  def self.find_by(opts)
    self.all.detect { |obj| obj.slug == opts[:slug] }
  end

  ####################
  # Instance methods #
  ####################

  # called in load
  def initialize(content, slug)
    self.slug = slug
    content.each do |k, v|
      self.instance_variable_set("@#{k}",v)
    end
  rescue StandardError => e
    puts "There's a problem with file '#{slug}'"
    raise e
  end
end

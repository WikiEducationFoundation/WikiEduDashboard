class FromYaml

  # cattr_accessor would be cause children's implementations to conflict w/each other
  class << self
    attr_accessor :cache_key
  end
  
  attr_accessor :slug

  # Class Methods

  # called from the initializers/training_content.rb
  def self.load(args)
    collection = []

    self.cache_key = args[:cache_key]

    Dir.glob(args[:path_to_yaml]) do |yaml_file|
      slug = File.basename(yaml_file, ".yml")
      content = YAML.load_file(yaml_file).to_hashugar
      collection << self.new(content, slug)
    end
    Rails.cache.write args[:cache_key], collection
  end

  def self.all
    Rails.cache.read(self.cache_key)
  end

  def self.find_by(opts)
    self.all.detect { |obj| obj.slug == opts[:slug] }
  end

  # Instance Methods

  # called in load
  def initialize(content, slug)
    self.slug = slug
    content.each do |k, v|
      self.instance_variable_set("@#{k}",v)
    end
  end
  
end

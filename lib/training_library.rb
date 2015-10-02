class TrainingLibrary
  @@libs = []

  def self.all
    @@libs.any? ? @@libs : self.load
  end

  def self.find_library(opts)
    library_id = opts[:library]
    YAML.load_file("#{Rails.root}/training_content/libraries/#{library_id}.yml")
  end

  def self.find_module(opts)
    library_id = opts[:library]
    module_id = opts[:module]
    YAML.load_file("#{Rails.root}/training_content/libraries/#{library_id}/modules/#{module_id}.yml")
  end

  private

  def self.load
    Dir.glob(Rails.root.join('training_content/libraries/*.yml')).each do |library_file|
      library = YAML.load_file(library_file)
      @@libs << library
    end
    @@libs
  end

end


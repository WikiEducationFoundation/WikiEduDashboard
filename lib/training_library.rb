class TrainingLibrary
  @@libs = []

  def self.all
    @@libs.any? ? @@libs : self.load
  end

  def self.find(opts)
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


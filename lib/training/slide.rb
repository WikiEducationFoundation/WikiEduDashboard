module Training
  class Slide

    def self.all
      Dir.glob(Rails.root.join('training_content/libraries/*.yml')).each do |library_file|
        library = YAML.load_file(library_file)
        @@libs << library
      end
    end

  end
end

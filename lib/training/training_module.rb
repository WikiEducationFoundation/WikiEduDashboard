module Training
  class TrainingModule

    def self.all
      modules = []
      Dir.glob(Rails.root.join('training_content/modules/*.yml')).each do |mod_name|
        h = Hash.new
        h['slug'] = mod_name.split('/').last.gsub('.yml', '')
        h['data'] = YAML.load_file(mod_name)
        modules << h.to_hashugar
      end
      modules
    end

  end
end

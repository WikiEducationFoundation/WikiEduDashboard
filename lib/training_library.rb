require 'from_yaml'

class TrainingLibrary < FromYaml

  attr_accessor :name, :modules, :introduction, :categories
  alias_method :raw_modules, :modules 

  # Class Methods

  def self.load
    super path_to_yaml: "#{Rails.root}/training_content/libraries/*.yml", cache_key: "libraries"
  end


  # Instance Methods

  # raw_modules can be called to access the string representation;
  # #modules now returns the instances of TrainingModule
  def modules
    TrainingModule.all.find_all do |training_module|
      raw_modules.include?(training_module.slug)
    end
  end
  

end

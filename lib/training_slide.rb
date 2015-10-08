require 'from_yaml'

class TrainingSlide < FromYaml

  attr_accessor :name, :content, :title, :summary, :id, :slug, :assessment

  # Class Methods

  def self.load
    super path_to_yaml: "#{Rails.root}/training_content/slides/*.yml", cache_key: "slides"
  end
  
end

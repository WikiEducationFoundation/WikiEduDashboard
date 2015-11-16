require 'from_yaml'

#= Class representing an individual training slide
class TrainingSlide < FromYaml
  attr_accessor :name, :content, :subtitle, :title, :summary, :id, :slug, :assessment

  #################
  # Class Methods #
  #################
  def self.load(*)
    super path_to_yaml: File.join("#{Rails.root}/training_content/slides/**", '*.yml'),
          cache_key: 'slides',
          trim_id_from_filename: true
  end
end

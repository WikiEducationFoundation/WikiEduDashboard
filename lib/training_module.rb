require 'from_yaml'

class TrainingModule < FromYaml
  attr_accessor :name, :slides, :description, :estimated_ttc, :id, :intro
  alias_method :raw_slides, :slides

  #################
  # Class methods #
  #################
  def self.load(*)
    super path_to_yaml: "#{Rails.root}/training_content/modules/*.yml",
          cache_key: 'modules'
  end

  def self.find(id)
    all.detect { |training_module| training_module.id == id }
  end

  ####################
  # Instance methods #
  ####################

  # raw_slides can be called to access the string representation;
  # #slides now returns the instances of TrainingSlide
  def slides
    slides = TrainingSlide.all.select { |slide| raw_slides.collect(&:slug).include?(slide.slug) }
    slugs = raw_slides.collect(&:slug)
    slides.sort { |a, b| slugs.index(a.slug) <=> slugs.index(b.slug) }
  end
end

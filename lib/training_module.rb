# frozen_string_literal: true
require "#{Rails.root}/lib/training/training_base"
require "#{Rails.root}/lib/training_slide"

class TrainingModule < TrainingBase
  attr_accessor :name, :slides, :description, :estimated_ttc, :id
  alias raw_slides slides

  #################
  # Class methods #
  #################
  def self.find(id)
    all.detect { |training_module| training_module.id == id }
  end

  def self.cache_key
    'modules'
  end

  def self.path_to_yaml
    "#{base_path}/modules/*.yml"
  end

  def self.wiki_base_page
    ENV['training_modules_wiki_page']
  end

  def self.trim_id_from_filename
    false
  end
  ####################
  # Instance methods #
  ####################

  # raw_slides can be called to access the string representation;
  # #slides now returns the instances of TrainingSlide
  def slides
    return @sorted_slides unless @sorted_slides.nil?
    slides = TrainingSlide.all.select { |slide| slide_slugs.include?(slide.slug) }
    @sorted_slides = slides.sort { |a, b| slide_slugs.index(a.slug) <=> slide_slugs.index(b.slug) }
  end

  def valid?
    required_attributes = [id, name, slug, description, slides]
    required_attributes.all?
  end

  def slide_slugs
    @slide_slugs ||= raw_slides.map(&:slug)
  end

  # This reloads all the library and module content, but only updates the slides
  # for this module.
  def reload
    TrainingLibrary.flush
    TrainingModule.flush
    TrainingLibrary.load
    TrainingModule.load

    TrainingSlide.load(slug_whitelist: TrainingModule.find(id).slide_slugs)

    # After updating the module's slides, we must flush and update it again
    TrainingModule.flush
    TrainingModule.load
  end
end

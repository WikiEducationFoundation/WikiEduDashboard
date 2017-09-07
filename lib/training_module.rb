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
    slides = TrainingSlide.all.select { |slide| raw_slides.collect(&:slug).include?(slide.slug) }
    slugs = raw_slides.collect(&:slug)
    @sorted_slides = slides.sort { |a, b| slugs.index(a.slug) <=> slugs.index(b.slug) }
  end

  def valid?
    required_attributes = [id, name, slug, description, slides]
    required_attributes.all?
  end
end

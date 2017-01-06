# frozen_string_literal: true
require "#{Rails.root}/lib/training/training_base"

class TrainingModule < TrainingBase
  attr_accessor :name, :slides, :description, :estimated_ttc, :id
  alias raw_slides slides

  #################
  # Class methods #
  #################
  def self.load(load_all: false, **)
    super path_to_yaml: "#{base_path}/modules/*.yml",
          wiki_base_page: 'User:Ragesoss/modules',
          cache_key: 'modules',
          load_all: load_all
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

  def valid?
    required_attributes = [id, name, slug, description, slides]
    required_attributes.all?
  end
end

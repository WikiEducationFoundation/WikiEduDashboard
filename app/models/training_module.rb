# frozen_string_literal: true
# == Schema Information
#
# Table name: training_slides
#
#  id             :bigint(8)        not null, primary key
#  name           :string(255)
#  wiki_page      :string(255)
#  slug           :string(255)
#  slide_ids      :string(255)
#  estimated_ttc  :string(255)
#  description    :text(65535)
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#

require_dependency "#{Rails.root}/lib/training/training_base"
require_dependency "#{Rails.root}/lib/training_library"

#= Class representing an individual training slide
class TrainingModule < ApplicationRecord
  validates_presence_of :id, :name, :slug
  serialize :slide_ids, Array
  has_many :training_slides

  #################
  # Class methods #
  #################

  def self.base_path
    TrainingBase.base_path
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

  def self.load
    TrainingBase.load(content_class: self)
  end

  def self.load_all
    TrainingLibrary.flush
    if Features.wiki_trainings?
      TrainingModule.load
      TrainingSlide.load
      TrainingModule.load
      TrainingLibrary.load
    else
      TrainingLibrary.load
      TrainingModule.load
      TrainingSlide.load
    end
  end

  def self.inflate(content, slug, wiki_page = nil)
    training_module = TrainingModule.find_or_initialize_by(id: content['id'])
    training_module.name = content['name']
    training_module.wiki_page = wiki_page
    training_module.slug = slug
    training_module.estimated_ttc = content['estimated_ttc']
    training_module.description = content['description']
    slugs = content['slides'].map { |slide| slide['slug'] }
    ids = TrainingSlide.where(slug: slugs).pluck(:id, :slug).sort_by do |_i, s|
      slugs.index s
    end.map(&:first)
    training_module.slide_ids = ids
    training_module.save
    training_module
  rescue StandardError => e
    puts "There's a problem with file '#{slug}'"
    raise e
  end

  # This reloads all the library and module content, but only updates the slides
  # for the module with the given slug.
  def self.reload_module(slug:)
    # First reload the libraries and modules so we have the new list of slugs
    # and can load slides for brand-new modules.
    TrainingLibrary.flush
    TrainingLibrary.load
    TrainingModule.load
    # Reload the requested module's slides
    training_module = TrainingModule.find_by(slug: slug)
    raise ModuleNotFound, "No module #{slug} found!" unless training_module
    TrainingSlide.load
  end

  def slides
    return @sorted_slides if @sorted_slides.present?
    selected_slides = TrainingSlide.where(id: slide_ids)
    @sorted_slides = selected_slides.sort_by { |slide| slide_ids.index slide.id }
  end

  class ModuleNotFound < StandardError; end
end

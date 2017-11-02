# frozen_string_literal: true

require "#{Rails.root}/lib/training/training_base"

#= Class representing an individual training slide
class TrainingSlide < TrainingBase
  attr_accessor :content, :title_prefix, :title, :summary, :id, :slug,
                :assessment, :translations, :buttonText

  #################
  # Class Methods #
  #################
  def self.cache_key
    'slides'
  end

  def self.wiki_base_page
    ENV['training_slides_wiki_page']
  end

  def self.path_to_yaml
    File.join("#{base_path}/slides/**", '*.yml')
  end

  def self.trim_id_from_filename
    true
  end
  ####################
  # Instance methods #
  ####################

  def valid?
    required_attributes = [id, slug, title, content]
    required_attributes.all?
  end
end

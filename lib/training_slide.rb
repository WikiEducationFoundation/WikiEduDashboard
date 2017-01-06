# frozen_string_literal: true
require "#{Rails.root}/lib/training/training_base"

#= Class representing an individual training slide
class TrainingSlide < TrainingBase
  attr_accessor :content, :title_prefix, :title, :summary, :id, :slug, :assessment, :translations

  #################
  # Class Methods #
  #################
  def self.load(load_all: true, **)
    super path_to_yaml: File.join("#{base_path}/slides/**", '*.yml'),
          trim_id_from_filename: true,
          wiki_base_page: 'User:Ragesoss/slides',
          cache_key: 'slides',
          load_all: load_all
  end

  ####################
  # Instance methods #
  ####################

  def valid?
    required_attributes = [id, slug, title, content]
    required_attributes.all?
  end
end

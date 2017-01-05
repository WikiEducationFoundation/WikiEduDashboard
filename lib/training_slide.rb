# frozen_string_literal: true
require "#{Rails.root}/lib/training/training_base"

#= Class representing an individual training slide
class TrainingSlide < TrainingBase
  attr_accessor :name, :content, :title_prefix, :title, :summary, :id, :slug, :assessment

  #################
  # Class Methods #
  #################
  def self.load(*)
    super path_to_yaml: File.join("#{base_path}/slides/**", '*.yml'),
          cache_key: 'slides',
          trim_id_from_filename: true
  end
end

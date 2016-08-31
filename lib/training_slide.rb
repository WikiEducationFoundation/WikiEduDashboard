# frozen_string_literal: true
require 'from_yaml'

#= Class representing an individual training slide
class TrainingSlide < FromYaml
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

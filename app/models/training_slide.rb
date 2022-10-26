# frozen_string_literal: true
# == Schema Information
#
# Table name: training_slides
#
#  id           :bigint(8)        not null, primary key
#  title        :string(255)
#  title_prefix :string(255)
#  summary      :string(255)
#  button_text  :string(255)
#  wiki_page    :string(255)
#  assessment   :text(65535)
#  content      :text(65535)
#  translations :text(16777215)
#  slug         :string(255)
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#

require_dependency "#{Rails.root}/lib/training/training_base"

#= Class representing an individual training slide
class TrainingSlide < ApplicationRecord
  validates_presence_of :id, :slug, :title
  serialize :assessment, Hash
  serialize :translations, Hash

  #################
  # Class Methods #
  #################
  def self.wiki_base_page
    ENV['training_slides_wiki_page']
  end

  def self.path_to_yaml
    File.join("#{base_path}/slides/**", '*.yml')
  end

  def self.trim_id_from_filename
    true
  end

  def self.load(slug_list: nil)
    TrainingBase.load(content_class: self, slug_list:)
  end

  def self.base_path
    TrainingBase.base_path
  end

  

  

  ####################
  # Instance methods #
  ####################

  def self.inflate(all_content, slug, wiki_page = nil)
    slide = TrainingSlide.find_or_initialize_by(id: all_content['id'])
    slide.slug = slug
    slide.wiki_page = wiki_page
    all_content.each do |key, value|
      slide.send("#{key}=", value)
    end
    slide.save
    slide
  rescue StandardError => e
    puts "There's a problem with file '#{slug}'"
    raise e
  end
end

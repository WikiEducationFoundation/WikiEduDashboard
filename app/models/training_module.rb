# frozen_string_literal: true
# == Schema Information
#
# Table name: training_modules
#
#  id            :bigint           not null, primary key
#  name          :string(255)
#  estimated_ttc :string(255)
#  wiki_page     :string(255)
#  slug          :string(255)
#  slide_slugs   :text(65535)
#  description   :text(65535)
#  translations  :text(16777215)
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  kind          :integer          default(0)
#  settings      :text(65535)
#

require_dependency "#{Rails.root}/lib/training/training_base"

#= Class representing an individual training module
class TrainingModule < ApplicationRecord
  attr_accessor :status

  serialize :slide_slugs, Array
  serialize :translations, Hash
  serialize :settings, Hash

  validates_uniqueness_of :slug, case_sensitive: false

  module Kinds
    TRAINING = 0
    EXERCISE = 1
    DISCUSSION = 2
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

  def self.base_path
    TrainingBase.base_path
  end

  def self.inflate(content, slug, wiki_page = nil)
    training_module = TrainingModule.find_or_initialize_by(id: content['id'])
    training_module.slug = slug
    training_module.wiki_page = wiki_page
    training_module.inflate_content_hash(content)
    training_module.kind = training_module_kind(content['kind'])
    validate_and_save(training_module, slug)
    training_module
  rescue StandardError, TypeError => e # rubocop:disable Lint/ShadowedException
    puts "There's a problem with file '#{slug}'" if Rails.env.development?
    raise e
  end

  def self.validate_and_save(training_module, slug)
    valid = training_module.valid?
    if training_module.errors[:slug].any?
      raise TrainingBase::DuplicateSlugError,
            "Duplicate TrainingModule slug detected: #{slug}"
    end
    training_module.save if valid
  end

  def self.training_module_kind(value)
    case value
    when 'exercise'
      TrainingModule::Kinds::EXERCISE
    when 'discussion'
      TrainingModule::Kinds::DISCUSSION
    else
      TrainingModule::Kinds::TRAINING
    end
  end

  ####################
  # Inflation helper #
  ####################
  def inflate_content_hash(content)
    self.name = content['name'] || content[:name]
    self.description = content['description'] || content[:description]
    self.estimated_ttc = content['estimated_ttc']
    self.translations = content['translations']
    self.settings = content['settings']
    self.slide_slugs = content['slides'].pluck('slug')
  end

  ####################
  # Instance methods #
  ####################

  def training?
    kind == TrainingModule::Kinds::TRAINING
  end

  def exercise?
    kind == TrainingModule::Kinds::EXERCISE
  end

  def slides
    return @sorted_slides if @sorted_slides.present?
    selected_slides = TrainingSlide.where(slug: slide_slugs)
    @sorted_slides = selected_slides.sort do |a, b|
      slide_slugs.index(a.slug) <=> slide_slugs.index(b.slug)
    end
  end

  def translated_name
    translated(:name) || name
  end

  def translated_description
    translated(:description) || description
  end

  def translated(key)
    translations.dig(I18n.locale.to_s, key)
  end

  def sandbox_location
    settings['sandbox_location']
  end

  # Returns the first library that has a category including the module slug.
  # It returns nil if no such library is found.
  def find_library_by_slug
    TrainingLibrary.all.detect { |tl| tl.training_module_slugs.include? slug }
  end

  # Returns a specific training library for the module,
  # or a default library if it is not found.
  def find_or_default_library
    find_library_by_slug || TrainingLibrary.first
  end

  class ModuleNotFound < StandardError; end
end

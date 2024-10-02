# frozen_string_literal: true
require_dependency "#{Rails.root}/lib/training/yaml_training_loader"
require_dependency "#{Rails.root}/lib/training/wiki_training_loader"
require_dependency "#{Rails.root}/app/models/application_record"
require_dependency "#{Rails.root}/app/models/setting"

class TrainingBase
  class << self
    attr_accessor :path_to_yaml
  end

  SETTING_KEYS = %w[training_libraries_update training_modules_update training_slides_update].freeze

  #################
  # Class methods #
  #################

  def self.load_async(slug_list: nil, content_class: self)
    if Features.wiki_trainings?
      WikiTrainingLoaderWorker.new.start_content_class_update_process(content_class, slug_list)
    else
      YamlTrainingLoader.new(content_class:, slug_list:).load_content
    end
  end

  def self.load(slug_list: nil, content_class: self)
    if Features.wiki_trainings?
      WikiTrainingLoader.new(content_class:, slug_list:).load_content
    else
      YamlTrainingLoader.new(content_class:, slug_list:).load_content
    end
  end

  # Called during manual :training_reload action.
  # This should regenerate all training content from yml files and/or wiki.
  def self.load_all
    TrainingLibrary.load
    TrainingModule.load
    if Features.wiki_trainings?
      TrainingModule.all.each { |tm| TrainingSlide.load(slug_list: tm.slide_slugs) }
    else
      TrainingSlide.load
    end
  end

  def self.base_path
    if ENV['training_path']
      "#{Rails.root}/#{ENV['training_path']}"
    else
      "#{Rails.root}/training_content/wiki_ed"
    end
  end

  def update_setting(key, status)
    setting = Setting.find_or_create_by(key:)
    setting.reload
    setting.value['update_status'] = status
    setting.value['update_error'] = nil
    setting.save
  end

  def self.check_setting(key)
    setting = Setting.find_or_create_by(key:)
    setting.reload
    setting.value['update_status'] != 2
  end

  def update_settings(status)
    SETTING_KEYS.each { |key| update_setting(key, status) }
  end

  def self.update_running?
    SETTING_KEYS.each do |key|
      setting = Setting.find_or_initialize_by(key:)
      setting.reload
      return true if setting.value['update_status'] == 1
    end
    false
  end

  def self.update_process_error_message
    update_errors = []

    SETTING_KEYS.each do |key|
      next if check_setting(key)
      setting = Setting.find_or_create_by(key:)
      error_message = setting.value['update_error']
      update_errors << error_message unless error_message.nil?
    end

    "Errors in the update process:\n#{update_errors.compact.join("\n")}"
  end

  def self.error_in_update_process
    puts 'Checking for errors in update process...'
    SETTING_KEYS.any? do |key|
      !check_setting(key)
    end
  end

  def self.update_error(message, content_class)
    puts message, content_class
    setting_key = class_to_setting_key(content_class)

    if setting_key
      setting = Setting.find_or_create_by(key: setting_key)
      setting.reload
      setting_value = setting.value || {} # Initialize setting_value as an empty hash if it's nil
      setting_value['update_status'] = 2
      setting_value['update_error'] = message
      setting.value = setting_value
      setting.save
    end
  end

  def self.finish_content_class_update_process(content_class)
    setting_key = class_to_setting_key(content_class)

    if setting_key
      setting = Setting.find_or_create_by(key: setting_key)
      setting.reload
      setting_value = setting.value || {}
      setting_value['update_status'] = 0 unless setting_value['update_status'] == 2
      setting.value = setting_value
      setting.save
    end
  end

  def self.class_to_setting_key(content_class)
    {
      TrainingLibrary => 'training_libraries_update',
      TrainingModule => 'training_modules_update',
      TrainingSlide => 'training_slides_update'
    }[content_class]
  end

  def clear_error_messages
    SETTING_KEYS.all? do |key|
      setting = Setting.find_or_initialize_by(key:)
      setting.value['update_error'] = nil
      setting.save
    end
  end

  def update_process_state(status)
    update_settings(status)
  end

  class DuplicateSlugError < StandardError; end
end

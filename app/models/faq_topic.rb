# frozen_string_literal: true

class FaqTopic
  def self.setting_record
    @setting_record ||= Setting.find_or_create_by(key: 'faq_topics')
  end

  def self.all
    setting_record.value.keys.map { |slug| FaqTopic.new(slug) }
  end

  def self.update(slug:, name:, faqs:)
    setting_record.value[slug] = { name: name, faqs: faqs }
    setting_record.save
  end

  def self.delete(slug:)
    setting_record.value.delete(slug)
    setting_record.save
  end

  attr_reader :slug

  def initialize(slug)
    @slug = slug
    @details = FaqTopic.setting_record.value[@slug]
  end

  def name
    @details[:name]
  end

  def faqs
    Faq.where(id: @details[:faqs]).sort_by { |faq| @details[:faqs].index faq.id }
  end
end

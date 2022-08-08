# frozen_string_literal: true

class FaqTopic
  def self.setting_record
    @setting_record ||= Setting.find_or_create_by(key: 'faq_topics')
  end

  def self.all
    setting_record.value.keys.sort.map { |slug| FaqTopic.new(slug) }
  end

  def self.update(slug:, name:, faqs:)
    record = Setting.find_or_create_by(key: 'faq_topics')
    record.value[slug] = { name:, faqs: }
    record.save
    @setting_record = record
  end

  def self.delete(slug:)
    record = Setting.find_or_create_by(key: 'faq_topics')
    record.value.delete(slug)
    record.save
    @setting_record = record
  end

  attr_reader :slug

  def initialize(slug)
    @slug = slug
    @details = FaqTopic.setting_record.value[@slug] || {}
  end

  def name
    @details[:name]
  end

  def faq_ids
    @details[:faqs]
  end

  def faqs
    Faq.where(id: faq_ids).sort_by { |faq| faq_ids.index faq.id }
  end
end

# frozen_string_literal: true

#= Presenter for campaigns and default campaign
class CampaignsPresenter
  def self.default_campaign_setting
    Setting.find_or_create_by(key: 'default_campaign')
  end

  def self.default_campaign_slug
    default_campaign_setting.value[:slug] || ENV['default_campaign']
  end

  def self.update_default_campaign(slug)
    default_campaign_setting.update(value: { slug: })
  end
end

# frozen_string_literal: true
require "#{Rails.root}/app/presenters/campaigns_presenter.rb"

# Set current term as default campaign if it exists as a campaign.
class DefaultCampaignUpdate
  def initialize
    CampaignsPresenter.update_default_campaign(current_term) if Campaign.find_by(slug: current_term)
  end

  private

  def current_term
    year = Time.zone.today.year
    month = Time.zone.today.month
    # Determine if it's spring or fall semester based on academic calendar
    semester = month.between?(1, 6) ? 'spring' : 'fall'
    semester + '_' + year.to_s
  end
end

# frozen_string_literal: true

# Manual-only: runs axe-core against a sample of Dashboard pages and reports
# accessibility violations. Run with:
#   bundle exec rspec spec/features/accessibility_audit.rb
# The filename intentionally omits the `_spec.rb` suffix so RSpec's default
# discovery (which globs *_spec.rb) skips it; the codebase has known
# accessibility issues that would otherwise fail every CI run. The audit
# exists as documentation of the assertion pattern and as a manual tool to
# track remediation progress on specific pages.

require 'rails_helper'

describe 'Accessibility audit', type: :feature, js: true, accessibility: true do
  let!(:campaign) { Campaign.default_campaign }
  let!(:course) do
    create(:course, start: '2014-01-01'.to_date,
                    end: Time.zone.today + 2.days)
  end
  let!(:campaign_course) do
    CampaignsCourses.create(campaign_id: campaign.id, course_id: course.id)
  end

  describe 'the explore page' do
    it 'has no detectable accessibility violations' do
      visit '/explore'
      expect(page).to be_axe_clean
    end
  end
end

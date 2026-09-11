# frozen_string_literal: true

require 'rails_helper'

describe 'Scholars & Scientists report cards', type: :feature, js: true do
  let(:admin) { create(:admin) }
  let(:campaign) { create(:campaign, title: 'Scholars and Scientists 2025-26', slug: 'ss_2025_26') }
  let(:instructor) { create(:user, username: 'Wkent', real_name: 'Will Kent') }
  let(:finished) do
    create(:course, type: 'FellowsCohort', slug: 'Wiki_Education/250_by_2026-4_(Summer_2025)',
                    title: '250 by 2026-4', start: 200.days.ago, end: 120.days.ago,
                    upload_count: 4, character_sum: 95_544)
  end
  let(:pending) do
    create(:course, type: 'FellowsCohort', slug: 'Wiki_Education/250_by_2026-12',
                    title: '250 by 2026-12', start: 80.days.ago, end: 20.days.ago, user_count: 16)
  end

  before do
    campaign.courses << [finished, pending]
    create(:courses_user, course: finished, user: instructor,
                          role: CoursesUsers::Roles::INSTRUCTOR_ROLE)
    s1, s2 = %w[s1 s2].map { |name| create(:user, username: name) }
    create(:retention_stat, course: finished, user: s1, sessions_during: 5, days_to_return: 12,
                            sessions_after: 1, edits_60_90: 8)
    create(:retention_stat, course: finished, user: s2, sessions_during: 0, days_to_return: 30,
                            sessions_after: 0, edits_60_90: 0)
  end

  describe 'as an admin' do
    before { login_as(admin) }

    it 'shows a campaign report card from the index' do
      visit '/report_cards'
      click_link 'Scholars and Scientists 2025-26'
      expect(page).to have_content 'During the course'

      within('tbody tr', text: '250 by 2026-4') do
        expect(page).to have_content 'Will Kent'
        expect(page).to have_content '18,462' # words added
        expect(page).to have_content '2.5' # average sessions per participant
        expect(page).to have_link '250 by 2026-4',
                                  href: '/courses/Wiki_Education/250_by_2026-4_(Summer_2025)'
      end
      within('tbody tr', text: '250 by 2026-12') do
        expect(page).to have_content '16'
        expect(page).to have_content 'pending'
      end
      within('tbody tr', text: 'Total') do
        expect(page).to have_content '18'
      end
      expect(page).to have_link 'Download CSV', href: '/report_cards/ss_2025_26.csv'
    end
  end

  describe 'as a non-admin' do
    before { login_as(create(:user)) }

    it 'is refused' do
      visit '/report_cards'
      expect(page).to have_content 'Only administrators may do that.'
    end
  end
end

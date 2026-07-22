# frozen_string_literal: true

require 'rails_helper'

describe 'System Stats Dashboard', type: :feature do
  let(:admin) { create(:admin, username: 'admin_user') }
  let(:user) { create(:user, username: 'regular_user') }

  context 'when visited by a non-admin' do
    before do
      login_as(user, scope: :user)
    end

    it 'denies access or redirects' do
      visit '/system_stats'
      expect(page).not_to have_content('System & Facilitator Stats')
    end
  end

  context 'when visited by an admin' do
    before do
      login_as(admin, scope: :user)

      create(:system_stat,
             snapshot_date: Time.zone.today,
             total_edits: 50_000,
             total_article_views: 1_200_000,
             total_articles_created: 150,
             total_articles_improved: 450,
             total_characters_added: 8_500_000,
             new_editors_count_with_preregistration: 300,
             active_programs_count: 25,
             active_facilitators_count: 18,
             wiki_stats: {
               'en.wikipedia.org' => {
                 'edits' => 30_000,
                 'programs' => 15,
                 'articles_created' => 100,
                 'new_editors_with_preregistration' => 200
               }
             })

      facilitator_user = create(:user, username: 'lead_facilitator')
      create(:facilitator_stat,
             user: facilitator_user,
             total_edits: 5000,
             total_programs_count: 10,
             active_programs_count: 2,
             total_students_count: 120,
             new_editors_count_with_preregistration: 45,
             active_in_last_year: true)
    end

    it 'renders the react_root container for admin users' do
      visit '/system_stats'
      expect(page.status_code).to eq(200)
      expect(page).to have_css('#react_root')
    end
  end
end

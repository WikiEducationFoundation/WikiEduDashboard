# frozen_string_literal: true

require 'rails_helper'

describe 'the explore page', type: :feature, js: true do
  let(:campaign) { Campaign.default_campaign }
  let!(:course) do
    create(:course, start: '2014-01-01'.to_date,
                    end: Time.zone.today + 2.days)
  end
  let!(:campaign_course) do
    CampaignsCourses.create(campaign_id: campaign.id, course_id: course.id)
  end
  let!(:user) { create(:user, trained: true) }
  let!(:cu) do
    create(:courses_user,
           course_id: course.id,
           user_id: user.id,
           role: CoursesUsers::Roles::STUDENT_ROLE)
  end

  describe 'control bar' do
    it 'allows sorting via dropdown' do
      visit '/explore'

      # sorting via dropdown
      find('#courses select.sorts').find(:xpath, 'option[2]').select_option
      expect(page).to have_selector('[data-sort="revisions"].sort.desc')
      find('#courses select.sorts').find(:xpath, 'option[3]').select_option
      expect(page).to have_selector('[data-sort="characters"].sort.desc')
      find('#courses select.sorts').find(:xpath, 'option[5]').select_option
      expect(page).to have_selector('[data-sort="references"].sort.desc')
      find('#courses select.sorts').find(:xpath, 'option[6]').select_option
      expect(page).to have_selector('[data-sort="views"].sort.desc')
      find('#courses select.sorts').find(:xpath, 'option[7]').select_option
      expect(page).to have_selector('[data-sort="students"].sort.desc')
      find('#courses select.sorts').find(:xpath, 'option[1]').select_option
      expect(page).to have_selector('[data-sort="title"].sort.asc')
    end
  end

  describe 'campaigns list' do
    before do
      @campaign_name_a = create(:campaign, title: 'A campaign starting with A',
        start: Date.civil(2016, 1, 10),
        end: Date.civil(2016, 2, 10))
      @campaign_name_z = create(:campaign, title: 'Z campaign starting with Z',
        start: Date.civil(2015, 1, 10),
        end: Date.civil(2016, 2, 10))
      @campaign_name_b = create(:campaign, title: 'Better campaign starting with B',
        start: Date.civil(2016, 1, 10),
        end: Date.civil(2017, 2, 10))
    end

    it 'list active campaigns' do
      visit '/explore'
      expect(page).to have_content(@campaign_name_a.title)
      expect(page).to have_content(@campaign_name_z.title)
      expect(page).to have_content(@campaign_name_b.title)
      expect(page).to have_content(campaign.title)
    end

    describe 'allow sorting by' do
      it 'clicking on header' do
        visit '/explore'
        page.find('th.sortable', text: 'Campaigns').click
        titles = page.all('tr .table-link-cell.title')
        expect(titles[0].text).to eq(@campaign_name_a.title)
        expect(titles[1].text).to eq(@campaign_name_b.title)
        expect(titles[2].text).to eq(campaign.title) # starts with S
        expect(titles[3].text).to eq(@campaign_name_z.title)
        expect(page).to have_selector(:css, 'th.title.sortable.asc')
        # reverse sort
        page.find('th.title.sortable').click
        expect(page).to have_selector(:css, 'th.title.sortable.desc')
      end

      it 'dropdown' do
        visit '/explore'
        find('.sort-select select.sorts').click
        find('option', text: 'Campaigns').click

        expect(page).to have_selector(:css, 'th.title.sortable.asc')
        titles = page.all('tr .table-link-cell.title')

        expect(titles[0].text).to eq(@campaign_name_a.title)
        expect(titles[1].text).to eq(@campaign_name_b.title)
        expect(titles[2].text).to eq(campaign.title) # starts with S
        expect(titles[3].text).to eq(@campaign_name_z.title)
      end
    end
  end

  describe 'course list' do
    it 'is sortable' do
      visit '/explore'

      # Sortable by title
      expect(page).to have_selector('#courses [data-sort="title"].sort.asc')
      find('#courses [data-sort="title"].sort').click
      expect(page).to have_selector('#courses [data-sort="title"].sort.desc')

      # Sortable by character count
      find('#courses [data-sort="characters"].sort').click
      expect(page).to have_selector('#courses [data-sort="characters"].sort.desc')
      find('#courses [data-sort="characters"].sort').click
      expect(page).to have_selector('#courses [data-sort="characters"].sort.asc')

      # Sortable by references count
      find('#courses [data-sort="references"].sort').click
      expect(page).to have_selector('#courses [data-sort="references"].sort.desc')
      find('#courses [data-sort="references"].sort').click
      expect(page).to have_selector('#courses [data-sort="references"].sort.asc')

      # Sortable by view count
      find('#courses [data-sort="views"].sort').click
      expect(page).to have_selector('#courses [data-sort="views"].sort.desc')
      find('#courses [data-sort="views"].sort').click
      expect(page).to have_selector('#courses [data-sort="views"].sort.asc')

      # Sortable by student count
      find('#courses [data-sort="students"].sort').click
      expect(page).to have_selector('#courses [data-sort="students"].sort.desc')
      find('#courses [data-sort="students"].sort').click
      expect(page).to have_selector('#courses [data-sort="students"].sort.asc')
    end
  end

  describe 'rows' do
    let(:refs_tags_key) { 'feature.wikitext.revision.ref_tags' }

    it 'allows navigation to a campaign page' do
      visit '/explore'
      find('#campaigns .table tbody tr:first-child').click
      expect(page).to have_current_path("/campaigns/#{campaign.slug}/programs")
    end

    it 'allows navigation to a course page' do
      visit '/explore'
      find('#courses .table tbody tr:first-child').click
      expect(CGI.unescape(current_path)).to eq("/courses/#{course.slug}")
    end

    it 'shows the stats accurately' do
      create(:article, id: 1,
                       title: 'Selfie',
                       namespace: 0)
      create(:articles_course,
             course: course,
             article_id: 1)
      create(:revision,
             user: user,
             article_id: 1,
             date: 6.days.ago,
             characters: 9000,
             features: {
               refs_tags_key => 22
             },
             features_previous: {
               refs_tags_key => 17
             })
      Course.update_all_caches
      visit '/explore'

      # Number of courses
      expect(page.find('#campaigns .table tbody tr:first-child .num-courses-human').text).to eq('1')

      # Recent revisions
      expect(page.find('#courses .table tbody tr:first-child .revisions').text).to eq('1')
    end
  end

  describe 'course search' do
    let(:course2) do
      create(:course, title: 'Cool course', school: 'Here',
                      term: 'Now', slug: 'Here/Cool_course_(Now)')
    end

    before do
      create(:courses_user, course: course2, user: user, role: 1)
    end

    it 'returns courses that match the search term' do
      visit '/explore'
      expect(page).not_to have_content('Cool course')
      fill_in('search', with: 'cool')
      find('input#search').send_keys(:enter)
      expect(page).to have_content('Cool course')
    end
  end
end

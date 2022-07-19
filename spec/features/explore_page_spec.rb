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
  let(:admin) { create(:admin) }

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
        page.find('#campaigns_list th.sortable', text: 'Campaigns').click
        titles = page.all('#campaigns_list tr .table-link-cell.title')
        expect(titles[0].text).to eq(@campaign_name_a.title)
        expect(titles[1].text).to eq(@campaign_name_b.title)
        expect(titles[2].text).to eq(campaign.title) # starts with S
        expect(titles[3].text).to eq(@campaign_name_z.title)
        expect(page).to have_selector(:css, '#campaigns_list th.title.sortable.asc')
        # reverse sort
        page.find('#campaigns_list th.title.sortable').click
        expect(page).to have_selector(:css, '#campaigns_list th.title.sortable.desc')
      end

      it 'dropdown' do
        visit '/explore'
        find('#campaigns_list .sort-select select.sorts').click
        find('#campaigns_list option', text: 'Campaigns').click

        expect(page).to have_selector(:css, '#campaigns_list th.title.sortable.asc')
        titles = page.all('#campaigns_list tr .table-link-cell.title')

        expect(titles[0].text).to eq(@campaign_name_a.title)
        expect(titles[1].text).to eq(@campaign_name_b.title)
        expect(titles[2].text).to eq(campaign.title) # starts with S
        expect(titles[3].text).to eq(@campaign_name_z.title)
      end
    end

    it 'is clickable' do
      visit '/explore'
      find('#campaigns_list .table tbody tr', text: @campaign_name_a.title).click
      expect(page).to have_current_path("/campaigns/#{@campaign_name_a.slug}/programs")
    end
  end

  describe 'course list' do
    before do
      @course_active_name_a = create(
        :course,
        title: 'An awesome course starting with A',
        start: Date.civil(2016, 1, 10),
        end: Date.civil(2050, 1, 10),
        slug: 'foo/my_awesome_course'
      )
      @course_active_name_z = create(
        :course,
        title: 'Z course starting with Z',
        start: Date.civil(2016, 1, 10),
        end: Date.civil(2050, 1, 10),
        slug: 'foo/another_awesome_course'
      )
      @course_inactive = create(
        :course,
        title: 'course2',
        slug: 'foo/course2',
        start: Date.civil(2016, 1, 10),
        end: Date.civil(2016, 2, 10)
      )
      CampaignsCourses.create(
        course_id: @course_active_name_a.id,
        campaign_id: Campaign.default_campaign.id
      )
      CampaignsCourses.create(
        course_id: @course_active_name_z.id,
        campaign_id: Campaign.default_campaign.id
      )
      CampaignsCourses.create(
        course_id: @course_inactive.id,
        campaign_id: Campaign.default_campaign.id
      )
    end

    describe 'lists active courses of the default campaign' do
      it 'for admins' do
        allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(admin)
        visit '/explore'
        expect(page).to have_content(@course_active_name_a.title)
        expect(page).to have_content(@course_active_name_z.title)
        expect(page).not_to have_content(@course_inactive.title)
      end

      it 'for everyone else' do
        visit '/explore'
        expect(page).to have_content(@course_active_name_a.title)
        expect(page).to have_content(@course_active_name_z.title)
        expect(page).not_to have_content(@course_inactive.title)
      end
    end

    describe 'allow sorting by' do
      it 'clicking on header' do
        visit '/explore'
        page.find('#active_courses th.sortable', text: 'Courses').click
        titles = page.all('#active_courses tr .table-link-cell.title')
        expect(titles[0].text).to eq(@course_active_name_a.title)
        expect(titles[1].text).to eq(@course_active_name_z.title)
        expect(titles[2].text).to eq(course.title) # starts with Ų
        expect(page).to have_selector(:css, '#active_courses th.title.sortable.asc')

        # reverse sort
        page.find('#active_courses th.sortable', text: 'Courses').click
        titles = page.all('#active_courses tr .table-link-cell.title')

        expect(titles[0].text).to eq(course.title) # starts with Ų
        expect(titles[1].text).to eq(@course_active_name_z.title)
        expect(titles[2].text).to eq(@course_active_name_a.title)
        expect(page).to have_selector(:css, '#active_courses th.title.sortable.desc')
      end

      it 'dropdown' do
        visit '/explore'
        find('#active_courses .sort-select select.sorts').click
        find('#active_courses option', text: 'Courses').click

        titles = page.all('#active_courses tr .table-link-cell.title')

        expect(titles[0].text).to eq(@course_active_name_a.title)
        expect(titles[1].text).to eq(@course_active_name_z.title)
        expect(titles[2].text).to eq(course.title) # starts with Ų
        expect(page).to have_selector(:css, '#active_courses th.title.sortable.asc')
      end
    end

    it 'is clickable' do
      visit '/explore'
      find('#active_courses .table tbody tr', text: course.title).click
      expect(CGI.unescape(current_path)).to eq("/courses/#{course.slug}/")
    end
  end

  describe 'rows' do
    let(:refs_tags_key) { 'feature.wikitext.revision.ref_tags' }

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
      num_courses_human = page.find('#campaigns_list tr:first-child .num-courses-human').text
      expect(num_courses_human).to eq('1')

      # Recent revisions
      num_revisions = page.find('#active_courses .table tbody tr:first-child .revisions').text
      expect(num_revisions).to eq('1')
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
      fill_in('program-search', with: 'cool')
      find('input[name="program-search"]').send_keys(:enter)
      expect(page).to have_content('Cool course')
    end
  end
end

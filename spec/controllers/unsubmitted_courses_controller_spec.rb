# frozen_string_literal: true

require 'rails_helper'

describe UnsubmittedCoursesController, type: :request do
  describe '#index' do
    let!(:course) do
      create(:course, title: 'My awesome course',
                      start: 1.month.ago, end: 1.year.from_now)
    end

    let!(:course2) do
      create(:course, title: 'course2', slug: 'foo/course2',
                      start: 1.month.ago, end: 1.month.from_now)
    end

    let!(:stale_course) do
      create(:course, title: 'Stale draft', slug: 'foo/stale',
                      start: 4.months.ago, end: 3.months.ago)
    end

    it 'lists courses/programs that do not have a campaigns' do
      CampaignsCourses.create(course_id: course.id,
                              campaign_id: Campaign.default_campaign.id)

      get '/unsubmitted_courses'
      expect(response.body).not_to include(course.title)
      expect(response.body).to include(course2.title)
    end

    it 'shows course creation date' do
      get '/unsubmitted_courses'
      expect(response.body).to include(course.created_at.strftime('%Y-%m-%d'))
    end

    it 'hides courses that started more than three months ago by default' do
      get '/unsubmitted_courses'
      expect(response.body).not_to include(stale_course.title)
    end

    it 'shows courses that have not started yet' do
      upcoming = create(:course, title: 'Upcoming draft', slug: 'foo/upcoming',
                                 start: 6.months.from_now, end: 1.year.from_now)
      get '/unsubmitted_courses'
      expect(response.body).to include(upcoming.title)
    end

    it 'shows every unsubmitted course when all=true' do
      get '/unsubmitted_courses', params: { all: true }
      expect(response.body).to include(stale_course.title)
      expect(response.body).to include(course2.title)
    end

    it 'links to the full list from the default view' do
      get '/unsubmitted_courses'
      expect(Capybara.string(response.body))
        .to have_link('Show all', href: '/unsubmitted_courses?all=true')
    end

    it 'links back to the default view from the full list' do
      get '/unsubmitted_courses', params: { all: true }
      expect(Capybara.string(response.body))
        .to have_link('Show recent', href: '/unsubmitted_courses')
    end
  end
end

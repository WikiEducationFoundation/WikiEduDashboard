# frozen_string_literal: true

require 'rails_helper'

describe UnsubmittedCoursesController do
  render_views

  describe '#index' do
    let!(:course) do
      create(:course, title: 'My awesome course',
                      start: Date.civil(2016, 1, 10), end: Date.civil(2050, 1, 10))
    end

    let!(:course2) do
      create(:course, title: 'course2', slug: 'foo/course2',
                      start: Date.civil(2016, 1, 10), end: Date.civil(2016, 2, 10))
    end

    it 'should list courses/programs that do not have a campaigns' do
      CampaignsCourses.create(course_id: course.id,
                              campaign_id: Campaign.default_campaign.id)

      get :index
      expect(response.body).to_not have_content(course.title)
      expect(response.body).to have_content(course2.title)
    end

    it 'should show course creation date' do
      get :index
      expect(response.body).to have_content(course.created_at.strftime('%Y-%m-%d'))
    end
  end
end

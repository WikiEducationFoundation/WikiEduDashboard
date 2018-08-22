# frozen_string_literal: true

require 'rails_helper'

describe ActiveCoursesController do
  render_views

  describe '#index' do
    let!(:course) do
      create(:course, title: 'My awesome course', end: 1.day.from_now)
    end

    it 'should list a soon-ending course' do
      get :index
      expect(response.body).to have_content(course.title)
    end
  end
end

# frozen_string_literal: true

require 'rails_helper'

describe ActiveCoursesController, type: :request do
  describe '#index' do
    let!(:course) do
      create(:course, title: 'My awesome course', end: 1.day.from_now)
    end

    it 'lists a soon-ending course' do
      get '/active_courses.json'
      expect(response.body).to include(course.title)
    end
  end
end

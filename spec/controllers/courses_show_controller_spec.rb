# frozen_string_literal: true

require 'rails_helper'
require './lib/course_show_endpoints'

describe Courses::ShowController do
  let(:course) { create(:course) }
  let(:slug) { course.slug }
  let(:school) { slug.split('/')[0] }
  let(:titleterm) { slug.split('/')[1] }
  CourseShowEndPoints::ENDPOINTS.each do |endpoint|
    describe endpoint do
      context 'for an valid course path' do
        it 'renders a 200' do
          course_params = { school: school, titleterm: titleterm, endpoint: endpoint }
          get endpoint, params: course_params
          expect(response.status).to eq(200)
        end
      end
      # context 'when a spider tries index.php' do
      #   it 'renders a plain text 404' do
      #     course_params = { school: school, titleterm: titleterm, endpoint: 'index' }
      #     get :show, params: course_params, format: 'php'
      #     expect(response.status).to eq(404)
      #     expect(response.headers['Content-Type']).to match %r{text/plain}
      #   end
      # end
    end
  end
end

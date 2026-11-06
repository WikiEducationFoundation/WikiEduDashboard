# frozen_string_literal: true

require 'rails_helper'

describe 'Revision feedback and passcode retry', type: :request do
  let(:user) { create(:user, username: 'SignedInUser') }
  let(:admin) { create(:admin) }

  describe 'revision feedback for an assignment' do
    let(:private_course) { create(:course, slug: 'Hidden/Hidden_(term)', private: true) }
    let(:assignment) { create(:assignment, course: private_course, article_title: 'Selfie') }

    it 'is refused to a logged-out visitor when the course is private' do
      expect(LiftWingApi).not_to receive(:new)
      get '/revision_feedback', params: { title: 'Selfie', assignment_id: assignment.id,
                                          format: :json }
      expect(response.status).to eq(404)
    end
  end

  describe 'the incorrect passcode page' do
    it 'keeps a site-relative retry path' do
      get '/errors/incorrect_passcode', params: { retry: '/courses/School/Course_(term)' }
      expect(response.body).to include("action='/courses/School/Course_(term)'")
    end

    it 'drops a retry path that points at another site' do
      ['https://evil.example', '//evil.example', '/\\evil.example',
       "/\t/evil.example", "/\n/evil.example", "/\r/evil.example"].each do |path|
        get '/errors/incorrect_passcode', params: { retry: path }
        expect(response.body).not_to include('evil.example')
      end
    end
  end
end

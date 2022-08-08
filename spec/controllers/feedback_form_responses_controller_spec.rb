# frozen_string_literal: true

require 'rails_helper'

describe FeedbackFormResponsesController, type: :request do
  describe '#new' do
    it 'renders new' do
      get '/feedback'
      expect(controller).to render_template :new
    end

    describe 'sets ivars' do
      describe 'subject' do
        context 'referer in query params' do
          let(:referer) { 'wikipedia.org' }

          it 'sets referer from params' do
            get '/feedback', params: { referer: }
            expect(assigns(:subject)).to eq(referer)
          end
        end

        context 'referer on request object' do
          let(:referer) { 'bananas.com' }
          # workaround for https://github.com/rspec/rspec-rails/issues/1655

          it 'sets referer from request object' do
            get '/feedback', headers: { 'HTTP_REFERER' => referer }
            expect(assigns(:subject)).to eq(referer)
          end
        end
      end

      describe 'feedback_form_response' do
        it 'sets ivar to a new FeedbackFormResponse' do
          get '/feedback'
          expect(assigns(:feedback_form_response)).to be_a FeedbackFormResponse
        end
      end
    end
  end

  describe '#index' do
    let(:user) { create(:admin) }

    before do
      allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(user)
    end

    describe 'ivars' do
      it 'sets responses' do
        get '/feedback_form_responses'
        expect(assigns(:responses)).to match_array FeedbackFormResponse.all
      end
    end

    describe 'template' do
      it 'renders index' do
        get '/feedback_form_responses'
        expect(controller).to render_template :index
      end

      context 'not-signed in' do
        let(:user) { create(:user) }

        it "doesn't allow" do
          get '/feedback_form_responses'
          expect(response.status).to eq(302)
          expect(flash[:notice]).to eq("You don't have access to that page.")
        end
      end
    end
  end

  describe '#show' do
    let!(:form) { FeedbackFormResponse.create(body: 'bananas') }
    let(:user)  { create(:admin) }

    before do
      allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(user)
    end

    describe 'ivars' do
      it 'sets responses' do
        get "/feedback_form_responses/#{form.id}", params: { id: form.id }
        expect(assigns(:response)).to be_a FeedbackFormResponse
      end
    end

    describe 'template' do
      it 'renders index' do
        get '/feedback_form_responses'
        expect(controller).to render_template :index
      end

      context 'not-signed in' do
        let(:user) { create(:user) }

        it "doesn't allow" do
          get '/feedback_form_responses'
          expect(response.status).to eq(302)
          expect(flash[:notice]).to eq("You don't have access to that page.")
        end
      end
    end
  end

  describe '#create' do
    let(:user) { create(:user) }

    before do
      allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(user)
    end

    context 'non-admin' do
      let(:body) { 'bananas' }

      it 'creates successfully' do
        post '/feedback_form_responses', params: { feedback_form_response: { body: } }
        expect(FeedbackFormResponse.last.body).to eq(body)
        expect(response.status).to eq(302)
      end
    end
  end

  describe '#confirmation' do
    describe 'rendering' do
      it 'renders template' do
        get '/feedback/confirmation'
        expect(controller).to render_template :confirmation
      end
    end
  end
end

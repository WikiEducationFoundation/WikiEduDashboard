require 'rails_helper'

describe FeedbackFormResponsesController do

  describe '#new' do
    it 'renders new' do
      get :new
      expect(controller).to render_template :new
    end

    describe 'sets ivars' do
      describe 'subject' do
        context 'referrer in query params' do
          let(:referrer) { 'wikipedia.org' }
          it 'sets referrer from params' do
            get :new, { referrer: referrer  }
            expect(assigns(:subject)).to eq(referrer)
          end
        end
        context 'referrer on request object' do
          let(:referrer) { 'bananas.com' }
          before { allow(request).to receive(:referrer).and_return(referrer) }
          it 'sets referrer from request object' do
            get :new
            expect(assigns(:subject)).to eq(referrer)
          end
        end
      end
      describe 'feedback_form_response' do
        it 'sets ivar to a new FeedbackFormResponse' do
          get :new
          expect(assigns(:feedback_form_response)).to be_a FeedbackFormResponse
        end
      end
    end
  end

  describe '#index' do
    let(:user) { create(:admin) }
    before { allow(controller).to receive(:current_user).and_return(user) }

    describe 'ivars' do
      it 'sets responses' do
        get :index
        expect(assigns(:responses)).to match_array FeedbackFormResponse.all
      end
    end

    describe 'template' do
      it 'renders index' do
        get :index
        expect(controller).to render_template :index
      end

      context 'not-signed in' do
        let(:user) { create(:user) }
        it "doesn't allow" do
          get :index
          expect(response.status).to eq(302)
          expect(flash[:notice]).to eq("You don't have access to that page.")
        end
      end
    end
  end

  describe '#show' do
    let!(:form) { FeedbackFormResponse.create(body: 'bananas') }
    let(:user)  { create(:admin) }
    before { allow(controller).to receive(:current_user).and_return(user) }

    describe 'ivars' do
      it 'sets responses' do
        get :show, id: form.id
        expect(assigns(:response)).to be_a FeedbackFormResponse
      end
    end

    describe 'template' do
      it 'renders index' do
        get :index
        expect(controller).to render_template :index
      end

      context 'not-signed in' do
        let(:user) { create(:user) }
        it "doesn't allow" do
          get :index
          expect(response.status).to eq(302)
          expect(flash[:notice]).to eq("You don't have access to that page.")
        end
      end
    end
  end

  describe '#create' do
    let(:user)  { create(:user) }
    before { allow(controller).to receive(:current_user).and_return(user) }
    context 'non-admin' do
      let(:body) { 'bananas' }
      it 'creates successfully' do
        post :create, { feedback_form_response: { body: body } }
        expect(FeedbackFormResponse.last.body).to eq(body)
        expect(response.status).to eq(302)
      end
    end
  end

  describe '#confirmation' do
    describe 'rendering' do
      it 'renders template' do
        get :confirmation
        expect(controller).to render_template :confirmation
      end
    end
  end
end

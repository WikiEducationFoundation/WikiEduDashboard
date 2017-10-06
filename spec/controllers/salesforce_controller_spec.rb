# frozen_string_literal: true

require 'rails_helper'

describe SalesforceController do
  let(:course) { create(:course) }
  let(:admin) { create(:admin) }
  let(:user) { create(:user) }
  let(:article) { create(:article) }

  describe '#link' do
    context 'when user is an admin' do
      before { allow(controller).to receive(:current_user).and_return(admin) }

      it 'pushes to Salesforces and saves a valid Salesforce ID on the course' do
        expect_any_instance_of(Restforce::Data::Client).to receive(:update!).and_return(true)
        put :link, params: { course_id: course.id, salesforce_id: 'a0f1a000001Wyar' }
        expect(course.reload.flags[:salesforce_id]).to eq('a0f1a000001Wyar')
      end

      it 'raises an error for an invalid Salesforce ID' do
        expect { put :link, params: { course_id: course.id, salesforce_id: '1234' } }
          .to raise_error(SalesforceController::InvalidSalesforceIdError)
      end
    end

    context 'when user is not an admin' do
      before { allow(controller).to receive(:current_user).and_return(user) }
      it 'does not allow the action' do
        put :link, params: { course_id: course.id, salesforce_id: 'a0f1a000001Wyar' }
        expect(response.code).to eq('401')
      end
    end
  end

  describe '#update' do
    before { allow(controller).to receive(:current_user).and_return(admin) }

    let(:course) { create(:course, flags: { salesforce_id: 'a0f1a000001Wyar' }) }
    it 'updates the Salesforce record for a course' do
      expect_any_instance_of(Restforce::Data::Client).to receive(:update!).and_return(true)
      put :update, params: { course_id: course.id }
    end
  end

  describe '#create_media' do
    context 'when user is an admin' do
      before { allow(controller).to receive(:current_user).and_return(admin) }
      let(:subject) do
        put :create_media, params: {
          course_id: course.id,
          username: user.username,
          article_id:  article.id,
          before_rev_id: '0',
          after_rev_id: 123456
        }
      end
      it 'creates a media record and redirects to Salesforce' do
        expect_any_instance_of(Restforce::Data::Client).to receive(:create!).and_return('12345')

        expect(subject).to redirect_to(/12345/)
      end
    end

    context 'when user it not an admin' do
      before { allow(controller).to receive(:current_user).and_return(user) }
      it 'does not allow the action' do
        get :create_media
        expect(response.code).to eq('401')
      end
    end
  end
end

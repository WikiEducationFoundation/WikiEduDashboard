# frozen_string_literal: true
require 'rails_helper'

describe SalesforceController do
  let(:course) { create(:course) }
  let(:admin) { create(:admin) }
  let(:user) { create(:user) }

  describe '#link' do
    context 'when user is an admin' do
      before { allow(controller).to receive(:current_user).and_return(admin) }

      it 'saves a valid Salesforce ID on the course' do
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
end

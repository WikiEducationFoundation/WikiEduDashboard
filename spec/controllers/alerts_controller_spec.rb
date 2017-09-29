# frozen_string_literal: true

require 'rails_helper'

describe AlertsController do
  describe '#create' do
    let(:course) { create(:course) }
    let!(:user) { create(:user) }
    let(:target_user) { create(:admin, email: 'email@email.com') }
    let!(:courses_users) do
      create(:courses_user, course_id: course.id, user_id: user.id)
    end

    let(:alert_params) do
      { message: 'hello?', target_user_id: target_user.id, course_id: course.id }
    end

    before do
      allow(controller).to receive(:current_user).and_return(user)
      allow(controller).to receive(:user_signed_in?).and_return(true)
      controller.instance_variable_set(:@course, course)
    end

    it 'should create Need Help alert and send email' do
      post :create, params: alert_params, format: :json

      expect(response.status).to eq(200)
      expect(ActionMailer::Base.deliveries).not_to be_empty
      expect(ActionMailer::Base.deliveries.last.to).to include(target_user.email)
      expect(ActionMailer::Base.deliveries.last.subject)
        .to include("#{user.username} / #{course.slug}")
      expect(ActionMailer::Base.deliveries.last.parts[0].body).to include(alert_params[:message])
      expect(NeedHelpAlert.count).to eq(1)
      expect(NeedHelpAlert.last.email_sent_at).not_to be_nil
    end

    it 'renders a 500 if alert creation fails' do
      allow_any_instance_of(Alert).to receive(:save).and_return(false)
      post :create, params: alert_params, format: :json
      expect(response.status).to eq(500)
    end

    context 'when no target user is provided' do
      let(:alert_params) do
        { message: 'hello?', course_id: course.id }
      end
      it 'still works' do
        post :create, params: alert_params, format: :json
        expect(response.status).to eq(200)
        expect(NeedHelpAlert.count).to eq(1)
      end
    end

    context 'when the help button feature is disabled' do
      before do
        allow(Features).to receive(:enable_get_help_button?).and_return(false)
      end

      it 'raises a 400' do
        post :create, params: alert_params, format: :json
        expect(response.status).to eq(400)
      end
    end
  end

  describe '#resolve' do
    let(:alert) { create(:alert) }
    let(:admin) { create(:admin) }

    before do
      allow(controller).to receive(:current_user).and_return(admin)
    end

    it 'should update Alert resolved column to true' do
      put :resolve, params: { id: alert.id }, format: :json

      expect(response.status).to eq(200)
      expect(alert.reload.resolved).to be(true)
    end

    it 'should not update Alert unless its resolvable' do
      alert.update resolved: true

      put :resolve, params: { id: alert.id }, format: :json

      expect(response.status).to eq(422)
    end
  end
end

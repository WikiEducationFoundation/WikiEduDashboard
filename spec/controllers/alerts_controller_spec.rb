# frozen_string_literal: true

require 'rails_helper'

describe AlertsController, type: :request do
  describe '#create' do
    let(:course) { create(:course) }
    let!(:user) { create(:user) }
    let(:target_user) { create(:admin, email: 'email@email.com') }
    let!(:courses_users) do
      create(:courses_user, course_id: course.id, user_id: user.id)
    end

    let(:alert_params) do
      {
        message: 'hello?',
        target_user_id: target_user.id,
        course_id: course.id,
        format: :json,
        alert_type: 'NeedHelpAlert'
      }
    end

    before do
      allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(user)
      allow_any_instance_of(ApplicationController).to receive(:user_signed_in?).and_return(true)
      described_class.instance_variable_set(:@course, course)
    end

    it 'creates Need Help alert' do
      post '/alerts', params: alert_params

      expect(response.status).to eq(200)
      expect(NeedHelpAlert.count).to eq(1)

      expect(TicketDispenser::Ticket.count).to eq(1)

      ticket = TicketDispenser::Ticket.first
      expect(ticket.messages.count).to eq(1)
      expect(ticket.project).to eq(course)
      expect(ticket.owner).to eq(target_user)

      message = ticket.messages.first
      expect(message.sender).to eq(user)
      expect(message.content).to eq('hello?')
    end

    it 'renders a 500 if alert creation fails' do
      allow_any_instance_of(Alert).to receive(:save).and_return(false)
      post '/alerts', params: alert_params
      expect(response.status).to eq(500)
    end

    context 'when no target user is provided' do
      let(:alert_params) do
        { message: 'hello?', course_id: course.id, format: :json, alert_type: 'NeedHelpAlert' }
      end

      it 'still works' do
        post '/alerts', params: alert_params
        expect(response.status).to eq(200)
        expect(NeedHelpAlert.count).to eq(1)
      end
    end

    context 'when the help button feature is disabled' do
      before do
        allow(Features).to receive(:enable_get_help_button?).and_return(false)
      end

      it 'raises a 400' do
        post '/alerts', params: alert_params
        expect(response.status).to eq(400)
      end
    end
  end

  describe '#resolve' do
    let(:alert) { create(:alert) }
    let(:admin) { create(:admin) }
    let(:route) { "/alerts/#{alert.id}/resolve" }

    before do
      allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(admin)
    end

    it 'updates Alert resolved column to true' do
      put route, params: { format: :json }

      expect(response.status).to eq(200)
      expect(alert.reload.resolved).to be(true)
    end

    it 'does not update Alert unless its resolvable' do
      alert.update resolved: true

      put route, params: { format: :json }

      expect(response.status).to eq(422)
    end
  end

  describe '#notify_instructors' do
    let(:admin) { create(:admin) }
    let(:course) { create(:course) }
    let(:route) { '/alerts/notify_instructors' }

    let(:body_params) do
      {
        course_id: course.id,
        subject: 'Test Title',
        message: 'Dear Test, Its working?',
        bcc_to_salesforce: true
      }
    end

    let(:headers) do
      {
        CONTENT_TYPE: 'application/json',
        ACCEPT: 'application/json'
      }
    end

    before do
      allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(admin)
    end

    it 'create and send email alert to instructors' do
      post '/alerts/notify_instructors', params: body_params.to_json, headers: headers

      expect(response.status).to eq(201)
      expect(InstructorNotificationAlert.count).to eq(1)

      alert = InstructorNotificationAlert.first
      expect(alert.subject).to eq(body_params[:subject])
      expect(alert.message).to eq(body_params[:message])
    end
  end
end

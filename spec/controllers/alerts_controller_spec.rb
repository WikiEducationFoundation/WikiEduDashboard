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
      { message: 'hello?', target_user_id: target_user.id, course_id: course.id, format: :json }
    end

    before do
      allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(user)
      allow_any_instance_of(ApplicationController).to receive(:user_signed_in?).and_return(true)
      described_class.instance_variable_set(:@course, course)
    end

    it 'creates Need Help alert and send email' do
      post '/alerts', params: alert_params

      expect(response.status).to eq(200)
      expect(ActionMailer::Base.deliveries).not_to be_empty
      expect(ActionMailer::Base.deliveries.last.to).to include(target_user.email)
      expect(ActionMailer::Base.deliveries.last.subject)
        .to include("#{user.username} / #{course.slug}")
      expect(ActionMailer::Base.deliveries.last.parts[0].body).to include(alert_params[:message])
      expect(NeedHelpAlert.count).to eq(1)
      expect(NeedHelpAlert.last.email_sent_at).not_to be_nil

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
        { message: 'hello?', course_id: course.id, format: :json }
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
end

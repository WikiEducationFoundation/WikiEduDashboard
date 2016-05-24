require 'rails_helper'

describe AlertsController do
  describe '#create' do
    let!(:course)           { create(:course) }
    let!(:user)             { create(:test_user) }
    let!(:target_user)      { create(:test_user) }
    let!(:courses_users)    { create(:courses_user, course_id: course.id, user_id: user.id) }

    before do
      allow(controller).to receive(:current_user).and_return(user)
      allow(controller).to receive(:user_signed_in?).and_return(true)
      controller.instance_variable_set(:@course, course)
    end

    it 'should create Need Help alert and send email' do
      target_user.email = 'email@email.com'
      target_user.save

      alert_params = { message: 'hello?', target_user_id: target_user.id, course_id: course.id }
      post :create, alert_params, format: :json

      expect(response.status).to eq(200)
      expect(ActionMailer::Base.deliveries).not_to be_empty
      expect(ActionMailer::Base.deliveries.last.to).to include(target_user.email)
      expect(ActionMailer::Base.deliveries.last.subject).to include("#{user.username} / #{course.slug}")
      expect(ActionMailer::Base.deliveries.last.body).to include(alert_params[:message])
      expect(NeedHelpAlert.count).to eq(1)
      expect(NeedHelpAlert.last.email_sent_at).not_to be_nil
    end
  end
end

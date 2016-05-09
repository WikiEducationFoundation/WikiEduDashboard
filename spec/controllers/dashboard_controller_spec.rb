require 'rails_helper'

describe DashboardController do
  describe '#index' do
    context 'when the user is not logged it' do
      it 'redirects to landing page' do
        get 'index'
        expect(response.status).to eq(302)
      end
    end

    context 'when user is an admin' do
      let(:course) { create(:course, end: 1.day.ago) }
      let(:admin) { create(:admin) }
      before do
        allow(controller).to receive(:current_user).and_return(admin)
        create(:courses_user, user_id: admin.id, course_id: course.id)
      end

      it 'sets past courses to include just-ended ones' do
        get 'index'
        expect(assigns(:pres).past.count).to eq(1)
      end
    end
  end
end

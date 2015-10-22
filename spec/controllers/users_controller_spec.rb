require 'rails_helper'

describe UsersController do
  describe '#enroll' do
    let!(:course) { create(:course) }
    let(:request_params) do
      { course_id: course.slug, passcode: course.passcode, titleterm: 'foobar' }
    end
    let(:user) { create(:user) }

    before do
      allow(WikiEdits).to receive(:enroll_in_course)
      allow(WikiEdits).to receive(:update_course)
      allow(WikiEdits).to receive(:remove_assignment)
      allow(WikiEdits).to receive(:update_assignments)
      allow(controller).to receive(:current_user).and_return(user)
      allow(controller).to receive(:require_participating_user)
    end

    subject { response.status }

    context 'POST' do
      let(:post_params) do
        { id: course.slug, user: { user_id: user.id, role: 0 }.as_json }
      end
      before { post 'enroll', post_params }
      it 'creates a CoursesUsers' do
        expect(CoursesUsers.count).to eq(1)
      end
      it 'renders a json template' do
        expect(subject).to render_template('users')
      end
      it 'succeeds' do
        expect(subject).to eq(200)
      end
    end

    context 'DELETE' do
      let(:delete_params) do
        { id: course.slug, user: { user_id: user.id, role: 0 }.as_json }
      end
      before do
        CoursesUsers.create(user_id: user.id, course_id: course.id, role: 0)
        article = create(:article)
        create(:assignment,
               course_id: course.id,
               user_id: user.id,
               article_id: article.id)
        delete 'enroll', delete_params
      end
      it 'destroys the courses user' do
        expect(CoursesUsers.count).to eq(0)
      end
      it 'succeeds' do
        expect(subject).to eq(200)
      end
    end
  end
end

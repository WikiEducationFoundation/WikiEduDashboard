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
      allow(WikiEdits).to receive(:update_assignments)
      allow(controller).to receive(:current_user).and_return(user)
    end

    subject { response.status }

    context 'GET' do
      it 'enrolls user (and redirects)' do
        get 'enroll', request_params
        expect(subject).to eq(302)
      end
    end

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

    # This is the HTTP verb that MS Word links use (for some reason)
    context 'HEAD' do
      it "doesn't error" do
        head 'enroll', request_params
        expect(subject).to eq(200)
      end
    end
  end
end

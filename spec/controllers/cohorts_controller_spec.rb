require 'rails_helper'

describe CohortsController do
  render_views

  describe '#create' do
    let(:user) { create(:user) }
    let(:admin) { create(:admin) }
    let(:title) { 'My New? Cohort 5!' }
    let(:expected_slug) { 'my_new_cohort_5' }
    let(:cohort_params) { { cohort: { title: title } } }

    context 'when user is an admin' do
      before do
        allow(controller).to receive(:current_user).and_return(admin)
      end

      it 'creates new cohorts' do
        post :create, cohort_params
        expect(Cohort.last.slug).to eq(expected_slug)
      end

      it 'does not create duplicate titles' do
        Cohort.create(title: title, slug: 'foo')
        post :create, cohort_params
        expect(Cohort.last.slug).to eq('foo')
      end

      it 'does not create duplicate slugs' do
        Cohort.create(title: 'foo', slug: expected_slug)
        post :create, cohort_params
        expect(Cohort.last.title).to eq('foo')
      end
    end

    context 'when user is not an admin' do
      before do
        allow(controller).to receive(:current_user).and_return(user)
      end

      it 'returns a 401 and does not create a cohort' do
        post :create, cohort_params
        expect(response.status).to eq(401)
        expect(Cohort.count).to eq(1)
      end
    end
  end

  describe '#students' do
    let(:course) { create(:course) }
    let(:cohort) { create(:cohort) }
    let(:student) { create(:user) }

    before do
      cohort.courses << course
      create(:courses_user, course_id: course.id, user_id: student.id,
                            role: CoursesUsers::Roles::STUDENT_ROLE)
    end

    context 'without "course" option' do
      let(:request_params) { { slug: cohort.slug, format: :csv } }

      it 'returns a csv of student usernames' do
        get :students, request_params
        expect(response.body).to have_content(student.username)
      end
    end

    context 'with "course" option' do
      let(:request_params) { { slug: cohort.slug, course: true, format: :csv } }

      it 'returns a csv of student usernames with course slugs' do
        get :students, request_params
        expect(response.body).to have_content(student.username)
        expect(response.body).to have_content(course.slug)
      end
    end
  end
end

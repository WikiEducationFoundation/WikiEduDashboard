require 'rails_helper'

describe CoursesController do

  describe '#index' do
    context 'signed in user' do
      let!(:course) { create(:course, listed: true, submitted: true, start: 2.months.ago, end: 2.months.from_now) }
      let!(:user) { create(:admin) }
      let!(:signed_in) { true }
      let!(:permissions) { 1 }
      let!(:cohort) { create(:cohort) }
      before do
        allow(controller).to receive(:current_user).and_return(user)
        allow(controller).to receive(:user_signed_in?).and_return(signed_in)
        allow(user).to receive(:permissions) { permissions }
      end

      context 'admin' do
        let!(:courses_user) { create(:courses_user, course_id: course.id, user_id: user.id) }
        it 'sets admin courses  and user courses if user is an admin' do
          get :index, cohort: cohort.slug
          expect(assigns(:admin_courses)).to eq(Course.submitted_listed)
        end
      end

      context 'student' do
        let!(:user) { create(:test_user) }
        before { allow(controller).to receive(:current_user).and_return(user) }
        let!(:courses_user) { create(:courses_user, course_id: course.id, user_id: user.id) }
        it 'sets users courses' do
          get :index, cohort: cohort.slug
          expect(assigns(:user_courses)).to include(course)
        end
      end
    end

    context 'params has key of cohort' do
      let!(:user) { create(:admin) }
      let(:signed_in) { false }
      before do
        allow(controller).to receive(:current_user).and_return(user)
        allow(controller).to receive(:user_signed_in?).and_return(signed_in)
      end
      context 'cohort none in params' do
        let!(:course) { create(:course, id: 100000, listed: true, submitted: false) }
        it 'sets the courses to unsubmitted' do
          get :index, cohort: 'none'
          expect(assigns(:cohort)).to be_an_instance_of(OpenStruct)
          expect(assigns(:courses)).to eq(Course.unsubmitted_listed)
          expect(assigns(:trained)).to be_nil
        end
      end

      context 'default cohort in env' do
        let!(:cohort) { create(:cohort) }
        before do
          ENV['default_cohort'] = 'spring_2015'
          allow(Figaro).to receive_message_chain(:env, :update_length).and_return(7)
        end
        it 'gets the slug' do
          get :index
          expect(assigns(:cohort)).to eq(cohort)
        end
      end

      context 'cohort not in params; no default' do
        before { ENV['default_cohort'] = nil }
        it 'raises' do
          expect{get :index}.to raise_error(ActionController::RoutingError)
        end
      end
    end
  end

  describe '#destroy' do
    let!(:course)           { create(:course) }
    let!(:user)             { create(:test_user) }
    let!(:courses_users)    { create(:courses_user, course_id: course.id, user_id: user.id) }
    let!(:article)          { create(:article) }
    let!(:articles_courses) { create(:articles_course, course_id: course.id, article_id: article.id) }
    let!(:assignment)       { create(:assignment, course_id: course.id) }
    let!(:cohorts_courses)  { create(:cohorts_course, course_id: course.id) }
    let!(:week)             { create(:week, course_id: course.id) }
    let!(:gradeable)        { create(:gradeable, gradeable_item_type: 'Course', gradeable_item_id: course.id) }
    let!(:admin)            { create(:admin, id: 2) }

    before do
      allow(controller).to receive(:current_user).and_return(admin)
      controller.instance_variable_set(:@course, course)
    end

    it 'calls update methods on WikiEdits' do
      expect(WikiEdits).to receive(:update_assignments)
      expect(WikiEdits).to receive(:update_course)
      delete :destroy, id: "#{course.slug}.json", format: :json
    end

    context 'destroy callbacks' do
      before do
        allow(WikiEdits).to receive(:update_assignments)
        allow(WikiEdits).to receive(:update_course)
      end

      it 'destroys associated models' do
        delete :destroy, id: "#{course.slug}.json", format: :json

        %w(CoursesUsers ArticlesCourses CohortsCourses).each do |model|
          expect {
            # metaprogramming for: CoursesUser.find(courses_user.id)
            Object.const_get(model).send(:find, send(model.underscore).id)
          }.to raise_error(ActiveRecord::RecordNotFound)
        end

        %i(assignment week gradeable).each do |model|
          expect{
            # metaprogramming for: Assigment.find(assignment.id)
            model.to_s.classify.constantize.send(:find, send(model).id)
          }.to raise_error(ActiveRecord::RecordNotFound)
        end
      end
    end
  end
end

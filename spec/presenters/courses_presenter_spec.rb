require 'rails_helper'
require_relative '../../app/presenters/courses_presenter'
require 'ostruct'

describe CoursesPresenter do
  describe '#admin_courses' do
    let(:admin)  { OpenStruct.new(admin?: is_admin) }
    let(:user)   { user }
    let(:cohort) { nil }
    before { create(:course, submitted: true, listed: true) }
    subject { described_class.new(user, cohort).admin_courses }
    context 'not signed in' do
      let(:user) { nil }
      it 'is nil' do
        expect(subject).to be_nil
      end
    end

    context 'signed in admin' do
      let(:user)     { admin }
      let(:is_admin) { true }
      it 'is the submitted listed scope' do
        expect(subject).to eq(Course.submitted_listed)
      end
    end
  end

  describe '#user_courses' do
    let(:admin)  { create(:admin) }
    let(:user)   { user }
    let(:cohort) { nil }
    subject { described_class.new(user, cohort).user_courses }
    context 'not signed in' do
      let(:user) { nil }
      it 'is nil' do
        expect(subject).to be_nil
      end
    end

    context 'not admin' do
      let(:user) { create(:test_user) }
      it 'is empty' do
        expect(subject).to be_empty
      end
    end

    context 'user is admin' do
      let!(:user)     { admin }
      let!(:is_admin) { true }
      let!(:course)  { create(:course, end: Time.zone.today + 4.months, listed: true) }
      let!(:c_user)  { create(:courses_user, course_id: course.id, user_id: user.id) }

      it 'returns the current and future listed courses for the user' do
        expect(subject).to include(course)
      end
    end
  end

  describe '#cohort' do
    let(:user)         { create(:admin) }
    let(:cohort_param) { cohort_param }
    subject { described_class.new(user, cohort_param).cohort }

    context 'cohort is "none"' do
      let(:cohort_param) { 'none' }
      it 'returns a null cohort object' do
        expect(subject).to be_an_instance_of(NullCohort)
      end
    end

    context 'cohorts' do
      context 'default cohort' do
        let!(:cohort)      { create(:cohort, slug: default) }
        let(:default)      { Figaro.env.default_cohort }
        let(:cohort_param) { default }
        it 'returns default cohort' do
          expect(subject).to eq(cohort)
        end
      end
      context 'valid cohort' do
        let!(:cohort) { create(:cohort) }
        let(:cohort_param) { cohort.slug }
        it 'returns that cohort' do
          expect(subject).to eq(cohort)
        end
      end
      context 'invalid cohort' do
        let(:cohort_param) { 'lolfakecohort' }
        it 'returns nil' do
          expect(subject).to be_nil
        end
      end
    end
  end

  describe '#courses' do
    let(:user) { create(:admin) }
    let(:cohort_param) { 'none' }
    let!(:course) { create(:course, listed: true, submitted: false, id: 10001) }
    subject { described_class.new(user, 'none').courses }

    context 'cohort is "none"' do
      it 'returns unsubmitted listed courses' do
        expect(subject).to include(course)
      end
    end

    context 'cohort is a valid cohort' do
      let(:course2) { create(:course, listed: true, submitted: false, id: 10002) }
      let(:cohort_param)    { Figaro.env.default_cohort }
      let(:cohort)          { create(:cohort, slug: cohort_param) }
      let!(:cohorts_course) { create(:cohorts_course, cohort_id: cohort.id, course_id: course.id) }
      it 'returns listed courses for the cohort' do
        expect(subject).to include(course2)
      end
    end
  end
end

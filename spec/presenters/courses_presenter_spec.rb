# frozen_string_literal: true

require 'rails_helper'
require_relative '../../app/presenters/courses_presenter'

describe CoursesPresenter do
  describe 'initialization via courses_list' do
    let!(:course) { create(:course, user_count: 2, trained_count: 1) }
    subject { described_class.new(current_user: nil, courses_list: Course.all) }
    it 'works with #courses, #active_courses, #user_count, #trained_count, #trained_percent' do
      expect(subject.courses.first).to eq(course)
      expect(subject.active_courses).not_to be_nil
      expect(subject.user_count).to eq(2)
      expect(subject.trained_count).to eq(1)
      expect(subject.trained_percent).to eq(50.0)
    end
  end

  describe '#user_courses' do
    let(:admin) { create(:admin) }
    let(:campaign) { nil }
    subject { described_class.new(current_user: user, campaign_param: campaign).user_courses }
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
      let!(:user) { admin }
      let!(:course)  { create(:course, end: Time.zone.today + 4.months) }
      let!(:c_user)  { create(:courses_user, course_id: course.id, user_id: user.id) }

      it 'returns the current and future courses for the user' do
        expect(subject).to include(course)
      end
    end
  end

  describe '#campaign' do
    let(:user)         { create(:admin) }
    let(:campaign_param) { campaign_param }
    subject { described_class.new(current_user: user, campaign_param: campaign_param).campaign }

    context 'campaigns' do
      context 'default campaign' do
        let(:campaign) { Campaign.find_by(slug: ENV['default_campaign']) }
        let(:default) { ENV['default_campaign'] }
        let(:campaign_param) { default }
        it 'returns default campaign' do
          expect(subject).to eq(campaign)
        end
      end
      context 'valid campaign' do
        let!(:campaign) { create(:campaign, slug: 'foo') }
        let(:campaign_param) { campaign.slug }
        it 'returns that campaign' do
          expect(subject).to eq(campaign)
        end
      end
      context 'invalid campaign' do
        let(:campaign_param) { 'lolfakecampaign' }
        it 'returns nil' do
          expect(subject).to be_nil
        end
      end
    end
  end

  describe 'searching campaign' do
    let!(:course) do
      create(:course, title: 'Math Foundations of Informatics',
                      school: 'Indiana University', term: 'Fall 2017')
    end
    subject { described_class.new(current_user: nil, courses_list: Course.all) }
    context 'find course based on title' do
      it 'returns courses when searching' do
        search = 'informatics'
        expect(subject.search_courses(search)).to_not be_empty
      end
    end
    context 'find course based on school' do
      it 'returns courses when searching' do
        search = 'indiana'
        expect(subject.search_courses(search)).to_not be_empty
      end
    end
    context 'find course based on term' do
      it 'returns courses when searching' do
        search = 'fall'
        expect(subject.search_courses(search)).to_not be_empty
      end
    end
  end
end

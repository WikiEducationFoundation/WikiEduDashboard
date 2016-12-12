# frozen_string_literal: true
require 'rails_helper'
require_relative '../../app/presenters/courses_presenter'
require 'ostruct'

describe CoursesPresenter do
  describe '#user_courses' do
    let(:admin)  { create(:admin) }
    let(:user)   { user }
    let(:campaign) { nil }
    subject { described_class.new(user, campaign).user_courses }
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
    subject { described_class.new(user, campaign_param).campaign }

    context 'campaign is "none"' do
      let(:campaign_param) { 'none' }
      it 'returns a null campaign object' do
        expect(subject).to be_an_instance_of(NullCampaign)
      end
    end

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

  describe '#courses' do
    let(:user) { create(:admin) }
    let(:campaign_param) { 'none' }
    let!(:course) { create(:course, submitted: false, id: 10001) }
    subject { described_class.new(user, 'none').courses }

    context 'when the campaign is "none"' do
      it 'returns unsubmitted courses' do
        expect(subject).to include(course)
      end
    end

    context 'when the campaign is a valid campaign' do
      let!(:course2) { create(:course, submitted: false, id: 10002) }
      let(:campaign_param)    { 'My Awesome Campaign' }
      puts Campaign.all.inspect
      puts Figaro.env.default_campaign.inspect
      let(:campaign)          { create(:campaign, slug: campaign_param) }
      let!(:campaigns_course) { create(:campaigns_course, campaign_id: campaign.id, course_id: course.id) }
      it 'returns courses for the campaign' do
        expect(subject).to include(course2)
      end
    end
  end
end

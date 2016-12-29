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
end

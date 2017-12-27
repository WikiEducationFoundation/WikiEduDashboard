# frozen_string_literal: true

# == Schema Information
#
# Table name: campaigns
#
#  id                   :integer          not null, primary key
#  title                :string(255)
#  slug                 :string(255)
#  url                  :string(255)
#  created_at           :datetime
#  updated_at           :datetime
#  description          :text(65535)
#  start                :datetime
#  end                  :datetime
#  template_description :text(65535)
#

require 'rails_helper'

describe Campaign do
  describe '.initialize_campaigns' do
    it 'create campaigns from application.yml' do
      Campaign.destroy_all
      campaigns = Campaign.all
      expect(campaigns).to be_empty

      Campaign.initialize_campaigns
      campaign = Campaign.first
      expect(campaign.url).to be_a(String)
      expect(campaign.title).to be_a(String)
      expect(campaign.slug).to be_a(String)

      # Make sure it still works if all the campaigns already exist
      Campaign.initialize_campaigns
    end
  end

  describe '.default_campaign' do
    it 'returns a campaign' do
      expect(Campaign.default_campaign).to be_a(Campaign)
    end
  end

  describe 'association' do
    it { should have_many(:campaigns_courses) }
    it { should have_many(:campaigns_users) }
    it { should have_many(:question_group_conditionals) }
    it { should have_many(:rapidfire_question_groups).through(:question_group_conditionals) }
    it { should have_many(:articles_courses) }
  end

  describe 'active campaign' do
    it 'should return campaigns without dates or where end date is in the future' do
      campaign = Campaign.create(
        title: 'My awesome 2010 campaign',
        start: Date.civil(2010, 1, 10),
        end: Date.civil(2010, 2, 10)
      )
      campaign2 = Campaign.create(
        title: 'My awesome 2050 campaign',
        start: Date.civil(2050, 1, 10),
        end: Date.civil(2050, 2, 10)
      )
      campaign3 = Campaign.create(
        title: 'My awesome early century campaign',
        start: Date.civil(2010, 1, 10),
        end: Date.civil(2040, 2, 10)
      )
      campaign4 = Campaign.create(title: 'My awesome campaign')
      expect(Campaign.active.collect(&:id)).to_not include(campaign.id)
      expect(Campaign.active.collect(&:id)).to include(campaign2.id)
      expect(Campaign.active.collect(&:id)).to include(campaign3.id)
      expect(Campaign.active.collect(&:id)).to include(campaign4.id)
    end
  end

  describe 'slug' do
    it 'creates a slug for the campaign based on the title' do
      campaign = Campaign.create(title: 'My awesome 2016 campaign')
      expect(campaign.slug).to eq('my_awesome_2016_campaign')
    end
    it 'handles non-ascii campaign titles' do
      title = 'Карыстальнік Група Беларусь 2016'
      campaign = Campaign.create(title: title)
      expect(campaign.slug).to eq('карыстальнік_група_беларусь_2016')
    end
  end

  describe 'date validation' do
    let(:campaign) { create(:campaign) }

    it 'should convert date-like strings to date object and save them' do
      campaign.start = '2016-01-10'
      campaign.end = '20160210'
      expect(campaign.valid?).to eq(true)
      expect(campaign.start).to eq(Date.civil(2016, 1, 10))
      expect(campaign.end).to eq(Date.civil(2016, 2, 10))
    end

    it 'should add an error if a date string is invalid' do
      campaign.start = '2016-01-10'
      campaign.end = 'not a valid date'
      expect(campaign.valid?).to eq(false)
      expect(campaign.start).to eq(Date.civil(2016, 1, 10)) # retains attempted value that was valid
      expect(campaign.errors.messages.keys).to include(:end)
    end

    it 'should add an error if one date is blank but the other is valid' do
      campaign.start = '2016-01-10'
      campaign.end = ''
      expect(campaign.valid?).to eq(false)
      expect(campaign.start).to eq(Date.civil(2016, 1, 10))
      expect(campaign.errors.messages.keys).to include(:end)
      expect(campaign.reload.start).to eq(nil)
    end

    it 'should add an error if the start date is after the end date' do
      campaign.start = '2016-02-10'
      campaign.end = '2016-01-10'
      expect(campaign.valid?).to eq(false)
      expect(campaign.errors.messages[:start]).to include(I18n.t('error.start_date_before_end_date'))
    end

    it 'should allow the date values to be changed to nil' do
      campaign.start = '2016-02-10'
      campaign.end = '2016-01-10'
      campaign.save
      campaign.start = nil
      campaign.end = '' # blank should be converted to nil
      expect(campaign.valid?).to eq(true)
      expect(campaign.start).to eq(nil)
      expect(campaign.end).to eq(nil)
    end

    it 'should set the default times for the dates' do
      campaign.start = '2016-01-10'
      campaign.end = '2016-02-10'
      campaign.save
      expect(campaign.start).to eq(DateTime.civil(2016, 1, 10, 0, 0, 0))
      expect(campaign.end).to eq(DateTime.civil(2016, 2, 10, 23, 59, 59))
    end
  end
end

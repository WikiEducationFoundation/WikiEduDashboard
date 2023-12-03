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
#  default_course_type  :string(255)
#  default_passcode     :string(255)
#  register_accounts    :boolean          default(FALSE)
#

require 'rails_helper'

describe Campaign do
  describe '.default_campaign' do
    it 'returns a the default campaign' do
      expect(described_class.default_campaign.slug).to eq(ENV['default_campaign'])
    end

    it 'returns another campaign if the default one is not found' do
      described_class.destroy_all
      described_class.create(title: 'Not the default one')
      expect(described_class.default_campaign).to be_a(described_class)
    end
  end

  describe 'association' do
    it { is_expected.to have_many(:campaigns_courses) }
    it { is_expected.to have_many(:campaigns_users) }
    it { is_expected.to have_many(:question_group_conditionals) }

    it 'has many question groups' do
      expect(subject).to have_many(:rapidfire_question_groups)
        .through(:question_group_conditionals)
    end

    it { is_expected.to have_many(:articles_courses) }
  end

  describe 'active campaign' do
    it 'returns campaigns without dates or where end date is in the future' do
      campaign = described_class.create(
        title: 'My awesome 2010 campaign',
        start: Date.civil(2010, 1, 10),
        end: Date.civil(2010, 2, 10)
      )
      campaign2 = described_class.create(
        title: 'My awesome 2050 campaign',
        start: Date.civil(2050, 1, 10),
        end: Date.civil(2050, 2, 10)
      )
      campaign3 = described_class.create(
        title: 'My awesome early century campaign',
        start: Date.civil(2010, 1, 10),
        end: Date.civil(2040, 2, 10)
      )
      campaign4 = described_class.create(title: 'My awesome campaign')
      expect(described_class.active.collect(&:id)).not_to include(campaign.id)
      expect(described_class.active.collect(&:id)).to include(campaign2.id)
      expect(described_class.active.collect(&:id)).to include(campaign3.id)
      expect(described_class.active.collect(&:id)).to include(campaign4.id)
    end
  end

  describe 'slug' do
    it 'creates a slug for the campaign based on the title' do
      campaign = described_class.create(title: 'My awesome 2016 campaign')
      expect(campaign.slug).to eq('my_awesome_2016_campaign')
    end

    it 'handles non-ascii campaign titles' do
      title = 'Карыстальнік Група Беларусь 2016'
      campaign = described_class.create(title:)
      expect(campaign.slug).to eq('карыстальнік_група_беларусь_2016')
    end
  end

  describe 'date validation' do
    let(:campaign) { create(:campaign) }

    it 'converts date-like strings to date object and save them' do
      campaign.start = '2016-01-10'
      campaign.end = '20160210'
      expect(campaign.valid?).to eq(true)
      expect(campaign.start.to_date).to eq(Date.civil(2016, 1, 10))
      expect(campaign.end.to_date).to eq(Date.civil(2016, 2, 10))
    end

    it 'adds an error if a date string is invalid' do
      campaign.start = '2016-01-10'
      campaign.end = 'not a valid date'
      expect(campaign.valid?).to eq(false)
      # retains attempted value that was valid
      expect(campaign.start.to_date).to eq(Date.civil(2016, 1, 10))
      expect(campaign.errors.messages.keys).to include(:end)
    end

    it 'adds an error if one date is blank but the other is valid' do
      campaign.start = '2016-01-10'
      campaign.end = ''
      expect(campaign.valid?).to eq(false)
      expect(campaign.start.to_date).to eq(Date.civil(2016, 1, 10))
      expect(campaign.errors.messages.keys).to include(:end)
      expect(campaign.reload.start).to eq(nil)
    end

    it 'adds an error if the start date is after the end date' do
      campaign.start = '2016-02-10'
      campaign.end = '2016-01-10'
      expect(campaign.valid?).to eq(false)
      expect(campaign.errors.messages[:start])
        .to include(I18n.t('error.start_date_before_end_date'))
    end

    it 'allows the date values to be changed to nil' do
      campaign.start = '2016-02-10'
      campaign.end = '2016-01-10'
      campaign.save
      campaign.start = nil
      campaign.end = '' # blank should be converted to nil
      expect(campaign.valid?).to eq(true)
      expect(campaign.start).to eq(nil)
      expect(campaign.end).to eq(nil)
    end

    it 'sets the default times for the dates' do
      campaign.start = '2016-01-10'
      campaign.end = '2016-02-10'
      campaign.save
      expect(campaign.start).to eq(Time.new(2016, 1, 10, 0, 0, 0, '+00:00'))
      expect(campaign.end).to be_within(1.second).of(Time.new(2016, 2, 10, 23, 59, 59, '+00:00'))
    end
  end

  describe '#course_string_prefix' do
    it 'is the dashboard default when default_course_type is not set' do
      result = described_class.new(title: 'no default').course_string_prefix
      expect(result).to eq('courses')
    end

    it 'is based on default_course_type when there is one' do
      result = described_class.new(title: 'generic default',
                                   default_course_type: 'BasicCourse').course_string_prefix
      expect(result).to eq('courses_generic')
      result = described_class
               .new(title: 'classroom default',
                    default_course_type: 'ClassroomProgramCourse').course_string_prefix
      expect(result).to eq('courses')
    end
  end
end

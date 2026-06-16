# frozen_string_literal: true

require 'rails_helper'

describe HarvestVerificationClaimPool do
  let(:wiki) { Wiki.get_or_create(language: 'en', project: 'wikipedia') }

  before do
    allow(HarvestCourseClaims).to receive(:new)
      .and_return(instance_double(HarvestCourseClaims, claims: []))
  end

  def active_course(subject)
    create(:course, subject:, slug: "Active/#{subject}_#{SecureRandom.hex(4)}",
                    start: 1.month.ago, end: 1.month.from_now)
  end

  def ended_course(subject, ended: 6.months.ago)
    create(:course, subject:, slug: "Ended/#{subject}_#{SecureRandom.hex(4)}",
                    start: 2.years.ago, end: ended)
  end

  it 'harvests ended courses whose subject matches an active course' do
    active_course('History')
    match = ended_course('History')
    ended_course('Chemistry') # no active Chemistry course — should be ignored
    described_class.new
    expect(HarvestCourseClaims).to have_received(:new).with(match).once
    expect(HarvestCourseClaims).to have_received(:new).once
  end

  it 'skips ended courses already represented in the pool' do
    active_course('History')
    done = ended_course('History', ended: 7.months.ago)
    fresh = ended_course('History', ended: 6.months.ago)
    VerificationClaim.create!(wiki:, sentence: 'Already harvested.', source_course: done)
    described_class.new
    expect(HarvestCourseClaims).to have_received(:new).with(fresh).once
    expect(HarvestCourseClaims).not_to have_received(:new).with(done)
  end

  it 'harvests nothing when no course is currently active' do
    ended_course('History')
    described_class.new
    expect(HarvestCourseClaims).not_to have_received(:new)
  end
end

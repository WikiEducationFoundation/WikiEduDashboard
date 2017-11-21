# frozen_string_literal: true

require 'rails_helper'

class MockR
  def eval(_string)
    nil
  end

  def before_count
    15
  end

  def before_mean
    5.6
  end

  def after_mean
    50.9
  end
end

describe HistogramPlotter do
  let(:course) { create(:course, id: 1, start: 1.year.ago, end: 1.day.from_now) }
  let(:subject) { described_class.plot(course: course) }
  let(:article) { create(:article) }
  let(:revision) do
    create(:revision, article: article, date: 1.day.ago, wp10: 70, wp10_previous: 1)
  end

  before(:each) do
    FileUtils.rm_rf "#{Rails.root}/public/assets/system"
    stub_const('R', MockR.new)
  end

  context 'when there is no article data' do
    it 'returns nil' do
      expect(subject).to be_nil
    end
  end

  context 'when there is article data' do
    before do
      course.articles << article
    end

    it 'returns an image path string' do
      expect(subject).to match(/.*png/)
    end
  end
end

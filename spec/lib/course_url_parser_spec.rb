# frozen_string_literal: true

require 'rails_helper'
require "#{Rails.root}/lib/utils/course_url_parser"

describe CourseUrlParser do
  let!(:course) { create(:course, slug: 'School/Course_(Term)') }

  it 'resolves a bare slug' do
    expect(described_class.new('School/Course_(Term)').course).to eq(course)
  end

  it 'resolves a full course URL that continues past the slug' do
    url = 'https://dashboard.wikiedu.org/courses/School/Course_(Term)/articles/available'
    expect(described_class.new(url).course).to eq(course)
  end

  it 'resolves a URL with percent-encoded parentheses and a query string' do
    url = 'https://dashboard.wikiedu.org/courses/School/Course_%28Term%29?enroll=abc'
    expect(described_class.new(url).course).to eq(course)
  end

  it 'resolves a courses/ path without a host, ignoring a .json suffix' do
    expect(described_class.new('/courses/School/Course_(Term).json').course).to eq(course)
  end

  it 'tolerates surrounding whitespace and slashes around a slug' do
    expect(described_class.new("  /School/Course_(Term)/ \n").course).to eq(course)
  end

  it 'returns nil for an unknown slug' do
    expect(described_class.new('School/Other_(Term)').course).to be_nil
  end

  it 'returns nil for nil input' do
    expect(described_class.new(nil).course).to be_nil
  end

  it 'returns nil for blank input' do
    expect(described_class.new('   ').course).to be_nil
  end
end

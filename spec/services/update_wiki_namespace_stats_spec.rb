# frozen_string_literal: true

require 'rails_helper'

describe UpdateWikiNamespaceStats do
  let(:course) { create(:course, start: Date.new(2022, 8, 1), end: Date.new(2022, 8, 2)) }
  let(:wiki) { Wiki.get_or_create(language: 'en', project: 'wikibooks') }
  let(:namespace) { 102 }
  let(:user1) { create(:user, username: 'Jamzze') } # user with cookbook edits
  let(:user2) { create(:user, username: 'FieldMarine') } # user with other namespace edits

  before do
    stub_wiki_validation
    course.campaigns << Campaign.first
    course.wikis << wiki
    JoinCourse.new(course:, user: user1, role: 0)
    JoinCourse.new(course:, user: user2, role: 0)
    allow_any_instance_of(Course).to receive(:tracked_namespaces).and_return([0, 102])
    VCR.use_cassette 'course_update' do
      UpdateCourseStats.new(course)
    end
    described_class.new(course, wiki, namespace)
  end

  it 'adds articles with only tracked namespaces to article_courses' do
    # namespaces of all the fetched revisions of course users
    fetched_namespaces = course.revisions.joins(:article).distinct.pluck('articles.namespace')
    # namespaces of article_courses
    article_namespaces = course.articles.distinct.pluck(:namespace)

    expect(fetched_namespaces).to include(0, 2, 3, 102)
    expect(article_namespaces).to include(0, 102)
    expect(article_namespaces).not_to include(2, 3)
  end

  it 'updates course_stat record with appropriate wiki-namespace key' do
    expect(course.course_stat).not_to be_nil

    stats = course.course_stat.stats_hash
    expect(stats).to have_key('en.wikibooks.org-namespace-102')
  end

  it 'updates wiki-namespace stats with appropriate keys' do
    stats = course.course_stat.stats_hash['en.wikibooks.org-namespace-102']

    expect(stats).to have_key(:edited_count)
    expect(stats).to have_key(:new_count)
    expect(stats).to have_key(:revision_count)
    expect(stats).to have_key(:user_count)
    expect(stats).to have_key(:word_count)
    expect(stats).to have_key(:reference_count)
    expect(stats).to have_key(:view_count)
  end

  it 'updates the wiki-namespace stats correctly' do
    stats = course.course_stat.stats_hash['en.wikibooks.org-namespace-102']

    expect(stats[:edited_count]).to eq 1
    expect(stats[:new_count]).to eq 1
    expect(stats[:revision_count]).to eq 4
    expect(stats[:user_count]).to eq 1
    expect(stats[:word_count]).to eq 262
    expect(stats[:reference_count]).to eq 0
    expect(stats[:view_count]).to eq 0
  end
end

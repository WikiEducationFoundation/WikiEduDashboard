# frozen_string_literal: true

require 'rails_helper'

describe UpdateWikiNamespaceStats do
  let(:course) { create(:course, start: Date.new(2022, 8, 1), end: Date.new(2022, 8, 2)) }
  let(:wikibooks) { Wiki.get_or_create(language: 'en', project: 'wikibooks') }
  let(:enwiki) { Wiki.get_or_create(language: 'en', project: 'wikipedia') }
  let(:cookbook_ns) { 102 }
  let(:file_ns) { 6 }
  let(:user1) { create(:user, username: 'Jamzze') } # user with cookbook edits
  let(:user2) { create(:user, username: 'FieldMarine') } # user with other namespace edits
  let(:user3) { create(:user, username: 'The Editor') } # user with en-wiki mainspace edits
  let(:cookbook_course_wiki) { create(:courses_wikis, course:, wiki: wikibooks) }
  let(:enwiki_course_wiki) { course.courses_wikis.find_by(wiki: enwiki) }

  before do
    stub_wiki_validation
    course.campaigns << Campaign.first

    create(:course_wiki_namespaces, courses_wikis: cookbook_course_wiki, namespace: cookbook_ns)
    create(:course_wiki_namespaces, courses_wikis: enwiki_course_wiki,
                                    namespace: file_ns) # not mainspace
    JoinCourse.new(course:, user: user1, role: 0)
    JoinCourse.new(course:, user: user2, role: 0)
    course.reload
    VCR.use_cassette 'course_update' do
      UpdateCourseStatsTimeslice.new(course)
    end
  end

  it 'adds articles with only tracked namespaces to article_courses' do
    pending 'This fails on data-rearchitecture branch.'
    # namespaces of all the fetched revisions of course users
    fetched_namespaces = course.revisions.joins(:article).distinct.pluck('articles.namespace')
    # namespaces of article_courses
    article_namespaces = course.articles.distinct.pluck(:namespace)

    expect(fetched_namespaces).to include(0, 2, 3, 102)
    expect(article_namespaces).to include(102)
    expect(article_namespaces).not_to include(0, 2, 3)
    pass_pending_spec
  end

  it 'only counts tracked namespaces for words added' do
    # there are words added to en.wiki mainspace by "The Editor"
    # but mainspace isn't being tracked.
    expect(course.word_count).to eq(0)
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

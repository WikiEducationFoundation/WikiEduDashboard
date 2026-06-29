# frozen_string_literal: true

require 'rails_helper'

describe 'Namespace-specific stats', type: :feature, js: true do
  let(:course) { create(:course, start: Date.new(2022, 8, 1), end: Date.new(2022, 8, 2)) }
  let(:wikibooks) { Wiki.get_or_create(language: 'en', project: 'wikibooks') }
  let(:cookbook_ns) { 102 }
  let(:user1) { create(:user, username: 'Jamzze') } # user with cookbook edits
  let(:user2) { create(:user, username: 'FieldMarine') } # user with other namespace edits
  let(:cookbook_course_wiki) { create(:courses_wikis, course:, wiki: wikibooks) }

  let(:superadmin) { create(:admin, permissions: 3) }

  before do
    stub_wiki_validation
    stub_token_request
    course.campaigns << Campaign.first

    create(:course_wiki_namespaces, courses_wikis: cookbook_course_wiki, namespace: 0)
    create(:course_wiki_namespaces, courses_wikis: cookbook_course_wiki, namespace: cookbook_ns)
    JoinCourse.new(course:, user: user1, role: 0)
    JoinCourse.new(course:, user: user2, role: 0)
    login_as superadmin
    allow(UpdateCourseStats).to receive(:new)
    create(:course_stats,
           stats_hash: { 'en.wikibooks.org-namespace-0':
    { edited_count: 1, new_count: 2, revision_count: 3,
      user_count: 4, word_count: 5, reference_count: 6, view_count: 7 },
   'en.wikibooks.org-namespace-102':
    { edited_count: 2, new_count: 4, revision_count: 4, user_count: 14,
      word_count: 15, reference_count: 16, view_count: 17 } }, course_id: course.id)
  end

  it 'generates and renders stats for Cookbook namespace on en.wikibooks.org' do
    visit "/courses/#{course.slug}/manual_update"
    expect(page).to have_content 'en.wikibooks.org - Mainspace'
    expect(page).to have_content "0\nTotal Edits"

    expect(page).to have_content 'en.wikibooks.org - Cookbook'
    find('.tab', text: 'en.wikibooks.org - Cookbook').click
    expect(page).to have_content "4\nTotal Edits"
  end
end

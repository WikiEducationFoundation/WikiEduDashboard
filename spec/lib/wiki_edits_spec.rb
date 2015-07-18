require 'rails_helper'
require "#{Rails.root}/lib/wiki_edits"

describe WikiEdits do
  # We're not testing any of the network stuff, nor whether the requests are
  # well-formatted, but at least this verifies that the flow is parsing tokens
  # in the expected way.
  before do
    stub_oauth_edit

    create(:course,
           id: 1)
    create(:user,
           id: 1,
           wiki_token: 'foo',
           wiki_secret: 'bar')
    create(:user,
           id: 2,
           wiki_token: 'foo',
           wiki_secret: 'bar')
    create(:courses_user,
           course_id: 1,
           user_id: 1)
    create(:courses_user,
           course_id: 1,
           user_id: 2)
  end

  describe '.notify_untrained' do
    it 'should post talk page messages on Wikipedia' do
      WikiEdits.notify_untrained(1, User.first)
    end
  end

  describe '.announce_course' do
    it 'should post to the userpage of the instructor and a noticeboard' do
      WikiEdits.announce_course(Course.first, User.first)
    end
  end

  describe '.enroll_in_course' do
    it 'should post to the userpage of the enrolling student' do
      WikiEdits.enroll_in_course(Course.first, User.first)
    end
  end

  describe '.update_course' do
    it 'should edit a Wikipedia page representing a course' do
      WikiEdits.update_course(Course.first, User.first)
      WikiEdits.update_course(Course.first, User.first, true)
    end
  end

  describe '.notify_users' do
    it 'should post talk page messages on Wikipedia' do
      params = { sectiontitle: 'My message headline',
                 text: 'My message to you',
                 summary: 'My edit summary' }
      WikiEdits.notify_users(User.first, User.all, params)
    end
  end

  describe '.update_assignments' do
    it 'should update talk pages and course page with assignment info' do
      create(:assignment,
             user_id: 1,
             course_id: 1,
             article_title: 'Selfie',
             role: 0)
      WikiEdits.update_assignments(User.first, Course.first, Assignment.all)
      WikiEdits.update_assignments(User.first, Course.first, nil, true)
    end
  end
  # Broken???
  # describe '.get_wiki_top_section' do
  #   it 'should return the top section content of a page' do
  #     title = 'Wikipedia:Education_program/Dashboard/test_ids'
  #     response = WikiEdits.get_wiki_top_section(title, User.first)
  #     expect(response.wikitext).to eq("439\n456\n351")
  #   end
  # end

end

require 'rails_helper'
require "#{Rails.root}/lib/wiki_edits"

ASSIGNEE_ROLE = 0
REVIEWER_ROLE = 1

describe WikiEdits do
  # We're not testing any of the network stuff, nor whether the requests are
  # well-formatted, but at least this verifies that the flow is parsing tokens
  # in the expected way.
  before do
    create(:course,
           id: 1,
           submitted: true,
           slug: 'University/Course_(term)')
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

  it 'should handle failed edits' do
    stub_oauth_edit_failure
    WikiEdits.notify_untrained(1, User.first)
  end

  it 'should handle edits that hit the abuse filter' do
    stub_oauth_edit_abusefilter
    WikiEdits.notify_untrained(1, User.first)
  end

  it 'should handle unexpected responses' do
    stub_oauth_edit_captcha
    WikiEdits.notify_untrained(1, User.first)
  end

  it 'should handle unexpected responses' do
    stub_oauth_edit_with_empty_response
    WikiEdits.notify_untrained(1, User.first)
  end

  # it 'should handle failed token requests' do
  #   stub_token_request_failure
  #   WikiEdits.notify_untrained(1, User.first)
  # end

  describe '.notify_untrained' do
    it 'should post talk page messages on Wikipedia' do
      stub_oauth_edit
      WikiEdits.notify_untrained(1, User.first)
    end
  end

  describe '.announce_course' do
    it 'should post to the userpage of the instructor and a noticeboard' do
      stub_oauth_edit
      WikiEdits.announce_course(Course.first, User.first)
    end
  end

  describe '.enroll_in_course' do
    it 'should post to the userpage of the enrolling student' do
      stub_oauth_edit
      WikiEdits.enroll_in_course(Course.first, User.first)
    end
  end

  describe '.update_course' do
    it 'should edit a Wikipedia page representing a course' do
      stub_oauth_edit
      WikiEdits.update_course(Course.first, User.first)
      WikiEdits.update_course(Course.first, User.first, true)
    end

    it 'should repost a clean version after hitting the spamblacklist' do
      stub_oauth_edit_abusefilter
      WikiEdits.update_course(Course.first, User.first)
    end
  end

  describe '.notify_users' do
    it 'should post talk page messages on Wikipedia' do
      stub_oauth_edit
      params = { sectiontitle: 'My message headline',
                 text: 'My message to you',
                 summary: 'My edit summary' }
      WikiEdits.notify_users(User.first, User.all, params)
    end
  end

  describe '.update_assignments' do
    it 'should update talk pages and course page with assignment info' do
      stub_oauth_edit
      create(:assignment,
             user_id: 1,
             course_id: 1,
             article_title: 'Selfie',
             role: ASSIGNEE_ROLE)
      create(:assignment,
             id: 2,
             user_id: 1,
             course_id: 1,
             article_title: 'Talk:Selfie',
             role: REVIEWER_ROLE)
      WikiEdits.update_assignments(User.first, Course.first, Assignment.all)
      WikiEdits.update_assignments(User.first, Course.first, nil)
      WikiEdits.update_assignments(User.first, Course.first, nil, true)
    end
  end
end

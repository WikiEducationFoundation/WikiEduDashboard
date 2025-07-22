# frozen_string_literal: true

require 'rails_helper'

describe SuspectedPlagiarismMailer do
  let(:course) { create(:course, title: 'Foo Course') }
  let(:user) { create(:user) }
  let(:instructor) { create(:user, username: 'instructor', email: 'instructor@wikiedu.org') }
  let(:ta) { create(:user, username: 'ta', email: 'ta@wikiedu.org') }

  let!(:courses_user) { create(:courses_user, course_id: course.id, user_id: user.id) }
  let(:content_expert) { create(:user, username: 'ce', greeter: true, email: 'ce@wikiedu.org') }
  before do
    create(:courses_user, course_id: course.id, user_id: instructor.id,
                          role: CoursesUsers::Roles::INSTRUCTOR_ROLE)
    create(:courses_user, course_id: course.id, user_id: ta.id,
                          role: CoursesUsers::Roles::INSTRUCTOR_ROLE)
    create(:courses_user, course_id: course.id, user_id: content_expert.id,
                          role: CoursesUsers::Roles::WIKI_ED_STAFF_ROLE)
    SpecialUsers.set_user('wikipedia_experts', content_expert.username)
  end

  let(:article) { create(:article) }
  let(:revision) do
    create(:revision, article_id: article.id,
                      user_id: user.id,
                      ithenticate_id: 10)
  end

  let(:details) do
    {
      submission_id: 'abcde',
      revision_id: 12345,
      wiki_id: Wiki.first.id
    }
  end
  let(:alert) do
    PossiblePlagiarismAlert.create!(user:, course:, article:, details:)
  end

  describe '.alert_content_expert' do
    let(:mail) { described_class.alert_content_expert(alert) }

    it 'delivers an email with course info to the content expert' do
      allow(Features).to receive(:email?).and_return(true)
      expect(mail.body.encoded).to match(course.title)
      expect(mail.to).to eq([instructor.email, ta.email])
      expect(mail.cc).to eq([content_expert.email])
    end
  end
end

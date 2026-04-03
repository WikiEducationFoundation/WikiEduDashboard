# frozen_string_literal: true

require 'rails_helper'

describe AiEditAlert do
  # Representative Wikipedia page titles for each page_type branch,
  # ordered to match the case statement in page_type.
  page_type_examples = [
    { title: 'User:Ragesoss/Choose an Article',         type: :choose_an_article   },
    { title: 'User:Ragesoss/Evaluate an Article',       type: :evaluate_an_article },
    { title: 'User:Ragesoss/Sandbox/Bibliography',      type: :bibliography        },
    { title: 'User:Ragesoss/Artwork title/Outline',     type: :outline             },
    { title: 'User:Ragesoss/Peer Review',               type: :peer_review         },
    { title: 'User:Ragesoss/Sandbox',                   type: :sandbox             },
    { title: 'Draft:Artwork title',                     type: :draft               },
    { title: 'Talk:Artwork title',                      type: :talk_page           },
    { title: 'User talk:Ragesoss',                      type: :user_talk           },
    { title: 'Template talk:WikiProject Medicine',      type: :template_talk       },
    { title: 'Artwork title',                           type: :mainspace           },
    { title: 'Wikipedia:Some page',                     type: :unknown             }
  ]

  let(:pangram_details) do
    {
      pangram_prediction: 'We are confident that this document is fully AI-generated',
      headline_result: 'Fully AI Generated',
      average_ai_likelihood: 0.97,
      max_ai_likelihood: 1.0,
      fraction_ai_content: 1.0,
      fraction_mixed_content: 0.0,
      predicted_ai_window_count: 3,
      pangram_share_link: 'https://www.pangram.com/history/example',
      pangram_version: 'v3'
    }
  end

  def build_alert(article_title)
    AiEditAlert.new(details: pangram_details.merge(article_title:, prior_alert_count_for_course: 0))
  end

  describe '#page_type' do
    page_type_examples.each do |example|
      it "returns :#{example[:type]} for '#{example[:title]}'" do
        alert = build_alert(example[:title])
        expect(alert.page_type).to eq(example[:type])
      end
    end
  end

  describe '#advice_email_type' do
    it 'returns :exercise for exercise page types' do
      %w[
        User:Ragesoss/Choose\ an\ Article
        User:Ragesoss/Evaluate\ an\ Article
        User:Ragesoss/Artwork\ title/Outline
      ].each do |title|
        expect(build_alert(title).advice_email_type).to eq(:exercise)
      end
    end

    it 'returns :sandbox for sandbox page types' do
      expect(build_alert('User:Ragesoss/Sandbox').advice_email_type).to eq(:sandbox)
    end

    it 'returns :mainspace for mainspace page types' do
      expect(build_alert('Artwork title').advice_email_type).to eq(:mainspace)
    end

    it 'returns nil for other page types' do
      other_titles = ['Draft:Artwork title', 'Talk:Artwork title',
                      'User:Ragesoss/Sandbox/Bibliography']
      other_titles.each do |title|
        expect(build_alert(title).advice_email_type).to be_nil
      end
    end
  end

  describe '.add_prior_alert_counts_by_type' do
    let(:course) { create(:course) }

    def create_sent_alert(article_title)
      create(:ai_edit_alert,
             course:,
             email_sent_at: Time.zone.now,
             details: { article_title:, prior_alert_count_for_course: 1 })
    end

    it 'sets all counts to zero when no prior alerts exist' do
      details = {}
      AiEditAlert.add_prior_alert_counts_by_type(course.id, details)
      expect(details[:prior_exercise_alerts]).to eq(0)
      expect(details[:prior_sandbox_alerts]).to eq(0)
      expect(details[:prior_mainspace_alerts]).to eq(0)
    end

    it 'counts exercise alerts separately from other types' do
      create_sent_alert('User:Ragesoss/Evaluate an Article')
      create_sent_alert('User:Ragesoss/Artwork title/Outline')
      details = {}
      AiEditAlert.add_prior_alert_counts_by_type(course.id, details)
      expect(details[:prior_exercise_alerts]).to eq(2)
      expect(details[:prior_sandbox_alerts]).to eq(0)
      expect(details[:prior_mainspace_alerts]).to eq(0)
    end

    it 'counts sandbox alerts separately from other types' do
      create_sent_alert('User:Ragesoss/Sandbox')
      details = {}
      AiEditAlert.add_prior_alert_counts_by_type(course.id, details)
      expect(details[:prior_exercise_alerts]).to eq(0)
      expect(details[:prior_sandbox_alerts]).to eq(1)
      expect(details[:prior_mainspace_alerts]).to eq(0)
    end

    it 'counts mainspace alerts separately from other types' do
      create_sent_alert('Artwork title')
      details = {}
      AiEditAlert.add_prior_alert_counts_by_type(course.id, details)
      expect(details[:prior_exercise_alerts]).to eq(0)
      expect(details[:prior_sandbox_alerts]).to eq(0)
      expect(details[:prior_mainspace_alerts]).to eq(1)
    end

    it 'ignores prior alerts without email_sent_at' do
      create(:ai_edit_alert, course:, email_sent_at: nil,
             details: { article_title: 'Artwork title', prior_alert_count_for_course: 1 })
      details = {}
      AiEditAlert.add_prior_alert_counts_by_type(course.id, details)
      expect(details[:prior_mainspace_alerts]).to eq(0)
    end

    it 'sets prior_omnibus_advice_sent to false when no prior alerts exist' do
      details = {}
      AiEditAlert.add_prior_alert_counts_by_type(course.id, details)
      expect(details[:prior_omnibus_advice_sent]).to be false
    end

    it 'sets prior_omnibus_advice_sent when a prior alert has prior_alert_count_for_course: 0' do
      create(:ai_edit_alert, course:, email_sent_at: Time.zone.now,
             details: { article_title: 'Artwork title', prior_alert_count_for_course: 0 })
      details = {}
      AiEditAlert.add_prior_alert_counts_by_type(course.id, details)
      expect(details[:prior_omnibus_advice_sent]).to be true
    end

    it 'does not set prior_omnibus_advice_sent for a new-system first alert' do
      # New-system alerts have prior_alert_count_for_course: 0 AND the per-type keys.
      # They should not be mistaken for legacy omnibus triggers.
      create(:ai_edit_alert, course:, email_sent_at: Time.zone.now,
             details: { article_title: 'Artwork title', prior_alert_count_for_course: 0,
                        prior_exercise_alerts: 0, prior_sandbox_alerts: 0,
                        prior_mainspace_alerts: 0, prior_omnibus_advice_sent: false })
      details = {}
      AiEditAlert.add_prior_alert_counts_by_type(course.id, details)
      expect(details[:prior_omnibus_advice_sent]).to be false
    end
  end

  describe '.generate_alert_from_pangram' do
    let(:course) { create(:course) }
    let(:user) { create(:user) }
    let(:article) { create(:article) }
    let(:revision_id) { 123_456_789 }

    def call_generate(revision_id: self.revision_id, user_id: user.id,
                      article_id: article.id, article_title: article.title)
      AiEditAlert.generate_alert_from_pangram(
        revision_id:,
        user_id:,
        course_id: course.id,
        article_id:,
        article_title:,
        pangram_details: pangram_details.dup
      )
    end

    context 'for the first alert in a course' do
      let(:user) { create(:user, email: 'student@example.com') }
      let(:instructor) { create(:user, username: 'Instructor', email: 'instructor@example.com') }
      let(:wiki_expert) do
        create(:user, username: 'WikiExpert', email: 'wiki_expert@example.com',
               permissions: 1, greeter: true)
      end
      let(:program_manager) do
        create(:user, username: 'ProgramManager', email: 'program_manager@example.com',
               permissions: 1, greeter: false)
      end

      before do
        create(:courses_user, user: instructor, course:,
               role: CoursesUsers::Roles::INSTRUCTOR_ROLE)
        create(:courses_user, user: wiki_expert, course:,
               role: CoursesUsers::Roles::WIKI_ED_STAFF_ROLE)
        create(:courses_user, user: program_manager, course:,
               role: CoursesUsers::Roles::WIKI_ED_STAFF_ROLE)
        allow(Features).to receive(:email?).and_return(true)
      end

      it 'sends appropriate emails' do
        # First AI alert, this one is a mainspace page. Triggers two emails.
        call_generate
        expect(ActionMailer::Base.deliveries.count).to eq(2)

        alert_email = ActionMailer::Base.deliveries.find { |m| m.subject.include?('Page:') }
        advice_email = ActionMailer::Base.deliveries.find { |m| m.subject.include?('instructor next steps') }

        expect(alert_email.to).to contain_exactly('student@example.com', 'instructor@example.com',
                                                   'wiki_expert@example.com')
        expect(alert_email.body.encoded).to include('added to Wikipedia in the course')
        expect(advice_email.to).to contain_exactly('instructor@example.com',
                                                   'wiki_expert@example.com')
        expect(advice_email.body.encoded).to include('mainspace edit')

        # Second alert for the same student and article. Triggers another email about the new
        # edit, but doesn't send a repeat advice email.
        call_generate(revision_id: revision_id + 1)
        expect(ActionMailer::Base.deliveries.count).to eq(3)

        second_alert_email = ActionMailer::Base.deliveries.last
        expect(second_alert_email.subject).to include('(again)')
        expect(second_alert_email.to).to contain_exactly('student@example.com',
                                                          'instructor@example.com',
                                                          'wiki_expert@example.com')
        expect(second_alert_email.body.encoded).to include('added to Wikipedia in the course')

        # Third alert: a different student's Evaluate an Article exercise page.
        # This one triggers a different advice email as well.
        student2 = create(:user, username: 'Student2', email: 'student2@example.com')
        exercise_sandbox = create(:article, title: 'Student2/Evaluate_an_Article',
                                            namespace: Article::Namespaces::USER)
        call_generate(revision_id: revision_id + 2, user_id: student2.id,
                      article_id: exercise_sandbox.id,
                      article_title: 'User:Student2/Evaluate an Article')
        expect(ActionMailer::Base.deliveries.count).to eq(5)

        third_alert_email, exercise_advice_email = ActionMailer::Base.deliveries.last(2)
        expect(third_alert_email.to).to contain_exactly('student2@example.com',
                                                        'instructor@example.com',
                                                        'wiki_expert@example.com')
        expect(third_alert_email.body.encoded).to include('added to Wikipedia as an exercise in the course') # rubocop:disable Layout/LineLength
        expect(exercise_advice_email.to).to contain_exactly('instructor@example.com',
                                                             'wiki_expert@example.com')
        expect(exercise_advice_email.body.encoded).to include('Our goal for these alert emails for exercises') # rubocop:disable Layout/LineLength

        # Fourth and fifth alerts use the first student's assignment-derived sandbox pages.
        create(:assignment, user_id: user.id, course_id: course.id,
               article_id: article.id, article_title: article.title,
               role: Assignment::Roles::ASSIGNED_ROLE, wiki_id: 1)

        # Fourth alert: bibliography sandbox derived from the assignment. No emails for this type.
        bibliography_sandbox = create(:article,
                                      title: "#{user.username}/#{article.title}/Bibliography",
                                      namespace: Article::Namespaces::USER)
        call_generate(revision_id: revision_id + 3,
                      article_id: bibliography_sandbox.id,
                      article_title: "User:#{user.username}/#{article.title}/Bibliography")
        expect(ActionMailer::Base.deliveries.count).to eq(5)

        # Fifth alert: the sandbox draft of the assigned article. Triggers a sandbox advice email.
        sandbox_draft = create(:article, title: "#{user.username}/#{article.title}",
                                         namespace: Article::Namespaces::USER)
        call_generate(revision_id: revision_id + 4,
                      article_id: sandbox_draft.id,
                      article_title: "User:#{user.username}/#{article.title}")
        expect(ActionMailer::Base.deliveries.count).to eq(7)

        sandbox_alert_email, sandbox_advice_email = ActionMailer::Base.deliveries.last(2)
        expect(sandbox_alert_email.to).to contain_exactly('student@example.com',
                                                           'instructor@example.com',
                                                           'wiki_expert@example.com')
        expect(sandbox_alert_email.body.encoded).to include('drafted for Wikipedia in the course')
        expect(sandbox_advice_email.to).to contain_exactly('instructor@example.com',
                                                            'wiki_expert@example.com')
        expect(sandbox_advice_email.body.encoded).to include("student's sandbox")
      end
    end
  end

  describe 'accessor methods' do
    it 'returns pangram fields from the details hash' do
      alert = build_alert('Artwork title')
      full_prediction = 'We are confident that this document is fully AI-generated'
      expect(alert.pangram_prediction).to eq(full_prediction)
      expect(alert.average_ai_likelihood).to eq(0.97)
      expect(alert.max_ai_likelihood).to eq(1.0)
      expect(alert.predicted_llm).to be_nil
    end
  end
end

# frozen_string_literal: true

require 'rails_helper'

describe SubmitCourseApplication do
  let(:course) { create(:fellows_cohort, end: 2.months.from_now) }
  let(:user) { create(:user) }
  let(:base_group) { create(:question_group, name: 'Base') }
  let(:theme_group) { create(:question_group, name: 'Theme') }
  let!(:background) { create(:q_long, question_group: base_group, question_text: 'Background') }
  let!(:pronouns) do
    create(:q_radio, question_group: base_group, question_text: 'Pronouns',
                     answer_options: "She/her\r\nHe/him\r\nSomething else")
  end
  # Required, but only shown when "Something else" is chosen.
  let!(:own_pronouns) do
    create(:q_short, question_group: base_group, question_text: 'Your pronouns',
                     conditionals: "#{pronouns.id}|=|Something_else|multi")
  end
  let!(:topics) do
    create(:q_checkbox, question_group: theme_group, question_text: 'Topics',
                        answer_options: "Elections\r\nVoting rights\r\nCivic information")
  end
  let!(:intro_text) { create(:q_text, question_group: theme_group, question_text: 'Read this') }

  before do
    CourseApplicationForm.create!(course:, open: true,
                                  question_group_ids: [base_group.id, theme_group.id])
  end

  def submit(answers)
    described_class.new(course:, user:, answers:)
  end

  let(:valid_answers) do
    {
      background.id.to_s => { answer_text: 'Historian of elections' },
      pronouns.id.to_s => { answer_text: 'She/her' },
      topics.id.to_s => { answer_text: ['', 'Elections', 'Civic information'] }
    }
  end

  context 'with every shown question answered' do
    let(:submission) { submit(valid_answers) }

    it 'saves the application' do
      expect(submission).to be_success
      expect(submission.application).to be_submitted
    end

    it 'saves one answer group per question group, linked to the application and course' do
      groups = submission.application.answer_groups
      expect(groups.map(&:question_group_id)).to contain_exactly(base_group.id, theme_group.id)
      expect(groups.map(&:course_id).uniq).to eq([course.id])
      expect(groups.map(&:user_id).uniq).to eq([user.id])
    end

    it 'stores checkbox answers the way survey submissions do' do
      submission
      answer = Rapidfire::Answer.find_by(question: topics)
      expect(answer.answer_text).to eq("Elections\r\nCivic information")
    end

    # Unmet conditional and display-only questions get no answer row.
    it 'saves no answer for a question the applicant was not shown' do
      submission
      expect(Rapidfire::Answer.where(question: [own_pronouns, intro_text])).to be_empty
    end
  end

  it 'requires a conditional question once its condition is met' do
    answers = valid_answers.merge(pronouns.id.to_s => { answer_text: 'Something else' })
    submission = submit(answers)
    expect(submission).not_to be_success
    expect(submission.answers_by_question_id[own_pronouns.id].errors).to be_present
  end

  it 'ignores an answer to a hidden question' do
    answers = valid_answers.merge(own_pronouns.id.to_s => { answer_text: 'xe/xem' })
    submit(answers)
    expect(Rapidfire::Answer.where(question: own_pronouns)).to be_empty
  end

  context 'with a required answer missing' do
    let(:submission) { submit(valid_answers.except(background.id.to_s)) }

    it 'saves nothing at all' do
      expect(submission).not_to be_success
      expect(CourseApplication.count).to eq(0)
      expect(Rapidfire::AnswerGroup.count).to eq(0)
      expect(Rapidfire::Answer.count).to eq(0)
    end

    it 'keeps the submitted answers, with the error on the missing one' do
      answers = submission.answers_by_question_id
      expect(answers[background.id].errors).to be_present
      expect(answers[pronouns.id].answer_text).to eq('She/her')
    end
  end

  it 'refuses a second application from the same person' do
    submit(valid_answers)
    expect(submit(valid_answers)).not_to be_success
    expect(CourseApplication.count).to eq(1)
  end
end

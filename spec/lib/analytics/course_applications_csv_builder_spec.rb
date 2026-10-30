# frozen_string_literal: true

require 'rails_helper'
require "#{Rails.root}/lib/analytics/course_applications_csv_builder"

describe CourseApplicationsCsvBuilder do
  let(:course) { create(:fellows_cohort, end: 2.months.from_now) }
  let(:base_group) { create(:question_group, name: 'Base') }
  let(:theme_group) { create(:question_group, name: 'Theme') }
  let!(:topics) do
    create(:q_checkbox, question_group: theme_group, question_text: 'Topics',
                        answer_options: "Elections\r\nVoting rights")
  end
  let!(:background) do
    create(:q_long, question_group: base_group, question_text: 'Background',
                    follow_up_question_text: 'Anything else?')
  end
  let(:applicant) { create(:user, username: 'Historian', email: 'h@example.edu') }

  before do
    CourseApplicationForm.create!(course:, open: true,
                                  question_group_ids: [base_group.id, theme_group.id])
    SubmitCourseApplication.new(course:, user: applicant, answers: {
                                  background.id.to_s => { answer_text: '=HYPERLINK("x")',
                                                          follow_up_answer_text: 'No' },
                                  topics.id.to_s => { answer_text: %w[Elections] }
                                })
  end

  let(:csv) { CSV.parse(described_class.new(course).generate_csv, headers: true) }

  it 'has a column per question and follow-up, in the form order' do
    expect(csv.headers.last(3)).to eq(['Background', 'Anything else?', 'Topics'])
  end

  it 'has a row per applicant with their details and answers' do
    row = csv.first
    expect(row['username']).to eq('Historian')
    expect(row['email']).to eq('h@example.edu')
    expect(row['status']).to eq('submitted')
    expect(row['Anything else?']).to eq('No')
    expect(row['Topics']).to eq('Elections')
  end

  it 'keeps answers from being run as spreadsheet formulas' do
    expect(csv.first['Background']).to eq(%('=HYPERLINK("x")))
  end
end

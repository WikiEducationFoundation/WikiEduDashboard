# frozen_string_literal: true

require 'rails_helper'
require "#{Rails.root}/lib/analytics/mentor_volunteers_csv_builder"

describe MentorVolunteersCsvBuilder do
  let(:campaign) { create(:campaign) }
  let(:course) do
    create(:course, title: 'Bio 101', school: 'Test University', term: 'Spring 2026',
                    subject: 'Biology', slug: 'Test_University/Bio_101_(Spring_2026)')
  end
  let(:instructor) do
    create(:user, username: 'bio_instructor', real_name: 'Bio Instructor',
                  email: 'bio@example.edu')
  end
  let(:courses_user) do
    create(:courses_user, course_id: course.id, user_id: instructor.id,
                          role: CoursesUsers::Roles::INSTRUCTOR_ROLE)
  end

  let(:mentor_option) { 'Become a mentor: guide a new instructor through their first term' }
  let(:other_options) { "Host a speaker\r\nWrite a blog post" }
  let(:survey) { create(:survey) }
  let(:question_group) { create(:question_group) }
  let(:question) do
    create(:q_checkbox, question_group_id: question_group.id,
                        answer_options: "Host a speaker\r\n#{mentor_option}\r\nWrite a blog post")
  end
  let(:survey_assignment) do
    create(:survey_assignment, survey_id: survey.id, published: true,
                               courses_user_role: CoursesUsers::Roles::INSTRUCTOR_ROLE)
  end
  let(:answer_group) do
    create(:answer_group, question_group_id: question_group.id, user_id: instructor.id)
  end

  let(:csv) { described_class.new(campaign).generate_csv }
  let(:lines) { csv.split("\n") }

  before do
    create(:campaigns_course, campaign_id: campaign.id, course_id: course.id)
    survey.rapidfire_question_groups << question_group
  end

  def create_notification(completed: true)
    create(:survey_notification, survey_assignment_id: survey_assignment.id,
                                 courses_users_id: courses_user.id,
                                 course_id: course.id, completed:)
  end

  def create_mentor_answer(question_id: question.id, group: answer_group)
    create(:answer, answer_group_id: group.id, question_id:,
                    answer_text: "Write a blog post\r\n#{mentor_option}")
  end

  it 'includes a row for a volunteer whose completed notification resolves the course' do
    create_notification
    create_mentor_answer
    expect(lines.first).to eq(described_class::CSV_HEADERS.join(','))
    expect(lines.second.split(',')).to eq(['Bio Instructor', 'bio_instructor',
                                           'bio@example.edu', 'Test University', 'Bio 101',
                                           'Biology', 'Spring 2026', course.slug])
  end

  it 'excludes answers that did not check the mentor option' do
    create_notification
    create(:answer, answer_group_id: answer_group.id, question_id: question.id,
                    answer_text: other_options)
    expect(lines.count).to eq(1)
  end

  it 'excludes responses resolving to a course outside the selected campaign' do
    create_notification
    create_mentor_answer
    other_campaign = create(:campaign, title: 'Other Campaign', slug: 'other_campaign')
    other_csv = described_class.new(other_campaign).generate_csv
    expect(other_csv.split("\n").count).to eq(1)
  end

  it 'falls back to the answer_group course when there is no notification' do
    answer_group.update(course_id: course.id)
    create_mentor_answer
    expect(lines.count).to eq(2)
    expect(csv).to include('bio_instructor')
  end

  it 'skips responses with no notification and no answer_group course' do
    create_mentor_answer
    expect(lines.count).to eq(1)
  end

  it 'does not resolve a course from an incomplete notification' do
    create_notification(completed: false)
    create_mentor_answer
    expect(lines.count).to eq(1)
  end

  it 'resolves the course when the question group belongs to multiple surveys' do
    second_survey = create(:survey, name: 'Second Survey')
    second_survey.rapidfire_question_groups << question_group
    second_assignment = create(:survey_assignment, survey_id: second_survey.id, published: true,
                               courses_user_role: CoursesUsers::Roles::INSTRUCTOR_ROLE)
    create(:survey_notification, survey_assignment_id: second_assignment.id,
                                 courses_users_id: courses_user.id,
                                 course_id: course.id, completed: true)
    create_mentor_answer
    expect(csv).to include('bio_instructor')
  end

  it 'matches per-term question clones by option wording rather than id' do
    create_notification
    clone = create(:q_checkbox, question_group_id: question_group.id,
                                question_text: '(Copy) Checkbox Question',
                                answer_options: question.answer_options)
    create_mentor_answer(question_id: clone.id)
    expect(csv).to include('bio_instructor')
  end

  it 'emits one row per (user, course) pair even with multiple matching answers' do
    create_notification
    clone = create(:q_checkbox, question_group_id: question_group.id,
                                answer_options: question.answer_options)
    create_mentor_answer
    create_mentor_answer(question_id: clone.id, group: create(:answer_group,
                                                              question_group_id: question_group.id,
                                                              user_id: instructor.id))
    expect(lines.count).to eq(2)
  end
end

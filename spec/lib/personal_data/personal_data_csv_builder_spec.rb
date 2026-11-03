# frozen_string_literal: true

require 'rails_helper'
require "#{Rails.root}/lib/personal_data/personal_data_csv_builder"

describe PersonalData::PersonalDataCsvBuilder, type: :request do
  let(:user) do
    create(:user,
           username: 'Sage the Rage',
           real_name: 'Sage Ross',
           email: 'sage@example.com',
           created_at: '2025-01-28 16:04:05 UTC',
           updated_at: '2025-01-28 16:04:05 UTC',
           locale: 'en',
           first_login: '2025-01-27 16:04:05 UTC')
  end
  let(:course) { create(:course) }
  let(:campaign) { create(:campaign) }

  before do
    create(:user_profile, user_id: user.id, bio: 'My bio',
                          location: 'NYC', institution: 'Wiki Ed')
    courses_user = create(:courses_user, user_id: user.id, course_id: course.id, role: 0)
    create(:assignment, user_id: user.id, course_id: course.id,
                        article_title: 'Siderocalin', role: 0)
    # Reload so the association picks up the assignment
    courses_user.reload
    create(:campaigns_user, user_id: user.id, campaign_id: campaign.id)
  end

  it 'logs in as the user, downloads personal data in CSV, and checks its content' do
    login_as(user)

    csv_content = described_class.new(user).generate_csv

    csv_lines = csv_content.split("\n")

    expect(csv_lines.count).to be >= 2

    # User info
    expect(csv_lines[0]).to include(
      'Username',
      'Real Name',
      'Email',
      'Created At',
      'Updated At',
      'Locale',
      'First Login'
    )

    expect(csv_lines[1]).to include(
      'Sage the Rage',
      'Sage Ross',
      'sage@example.com',
      '2025-01-28 16:04:05 UTC',
      '2025-01-28 16:04:05 UTC',
      'en',
      '2025-01-27 16:04:05 UTC'
    )

    # User profile info
    expect(csv_content).to include('Bio', 'Location', 'Institution')
    expect(csv_content).to include('My bio', 'NYC', 'Wiki Ed')

    # Course info
    expect(csv_content).to include('Course', 'Role', 'Character Sum MS')
    expect(csv_content).to include(course.slug)

    # Assignment info
    expect(csv_content).to include('Assignment Title', 'Assignment URL', 'Sandbox URL')
    expect(csv_content).to include('Siderocalin')

    # Campaign info
    expect(csv_content).to include('Campaign', 'Joined At')
    expect(csv_content).to include(campaign.slug)
  end

  describe 'LTI context info' do
    let(:binding) do
      LtiCourseBinding.create!(course:, lms_id: 'https://canvas.example.edu',
                               lms_family: 'canvas', lms_context_id: 'ctx-1',
                               lms_resource_link_id: 'rl-1')
    end

    before do
      LtiContext.create!(user:, lti_course_binding: binding,
                         user_lti_id: 'lti-user-9', lms_id: binding.lms_id,
                         lms_family: 'canvas',
                         roles: ['http://purl.imsglobal.org/vocab/lis/v2/' \
                                 'membership#Learner'],
                         lms_membership_status: 'Active',
                         linked_at: '2026-01-05 12:00:00 UTC')
    end

    it 'exports the LMS identity fields that survive the anonymized posture' do
      csv_content = described_class.new(user).generate_csv
      expect(csv_content).to include('LMS', 'LMS User ID', 'Roles (from LMS)',
                                     'Membership Status (from LMS)', 'Linked At')
      expect(csv_content).to include('canvas', 'lti-user-9', 'membership#Learner', 'Active')
    end

    it 'does not export LMS-supplied name or email columns' do
      csv_content = described_class.new(user).generate_csv
      expect(csv_content).not_to include('Email (from LMS)')
      expect(csv_content).not_to include('Name (from LMS)')
    end
  end

  describe 'course application info' do
    let(:cohort) { create(:fellows_cohort, slug: 'Wiki_Education/Workshop_(2027)') }
    let(:base) { create(:question_group, name: 'Base') }
    let(:theme) { create(:question_group, name: 'Theme') }
    let!(:background) do
      create(:q_long, question_group: base, question_text: 'Describe your research background')
    end
    let!(:topics) do
      create(:q_short, question_group: theme, question_text: 'Topics you would work on',
                       follow_up_question_text: 'Anything else?')
    end

    before do
      CourseApplicationForm.create!(course: cohort, open: true,
                                    question_group_ids: [base.id, theme.id])
      application = SubmitCourseApplication.new(course: cohort, user:, answers: {
        background.id.to_s => { answer_text: 'I study elections.' },
        topics.id.to_s => { answer_text: 'Voting rights', follow_up_answer_text: 'Maps' }
      }).application
      application.update!(staff_notes: 'Strong fit')
    end

    it 'exports each application with its answers, in form order' do
      csv = CSV.parse(described_class.new(user).generate_csv)
      start = csv.index(['Application', 'Status', 'Submitted At', 'Decided At'])
      expect(csv[start + 1].first(2)).to eq(['Wiki_Education/Workshop_(2027)', 'submitted'])
      expect(csv[start + 3]).to eq(['Describe your research background', 'I study elections.',
                                    nil, nil])
      expect(csv[start + 5]).to eq(['Topics you would work on', 'Voting rights',
                                    'Anything else?', 'Maps'])
    end

    it 'leaves out staff notes' do
      expect(described_class.new(user).generate_csv).not_to include('Strong fit')
    end
  end
end

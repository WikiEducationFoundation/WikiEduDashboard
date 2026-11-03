# frozen_string_literal: true

require 'csv'

module PersonalData
  class PersonalDataCsvBuilder
    def initialize(user)
      @user = user
    end

    def generate_csv
      CSV.generate(headers: true) do |csv|
        add_user_info(csv)
        add_user_profile_info(csv)
        add_course_info(csv)
        add_campaign_info(csv)
        add_lti_context_info(csv)
        add_course_application_info(csv)
      end
    end

    private

    def add_user_info(csv)
      csv << ['Username', 'Real Name', 'Email', 'Created At', 'Updated At', 'Locale', 'First Login']
      csv << [
        @user.username, @user.real_name, @user.email, @user.created_at,
        @user.updated_at, @user.locale, @user.first_login
      ]
    end

    def add_user_profile_info(csv)
      return unless @user.user_profile

      csv << [
        'Bio', 'Image File Name', 'Image Link', 'Image Updated At',
        'Location', 'Institution', 'Email Preferences'
      ]
      csv << [
        @user.user_profile.bio, @user.user_profile.image_file_name,
        @user.user_profile.image_file_link, @user.user_profile.image_updated_at,
        @user.user_profile.location, @user.user_profile.institution,
        @user.user_profile.email_preferences
      ]
    end

    def add_course_info(csv)
      @user.courses_users.includes(:course).each do |course_user|
        csv << [
          'Course', 'Role', 'Real Name', 'Role Description',
          'Character Sum MS', 'Character Sum US', 'Character Sum Draft',
          'Revision Count', 'References Count', 'Recent Revisions', 'Enrolled At'
        ]
        csv << [
          course_user.course.slug, course_user.role, course_user.real_name,
          course_user.role_description, course_user.character_sum_ms,
          course_user.character_sum_us, course_user.character_sum_draft,
          course_user.revision_count, course_user.references_count,
          course_user.recent_revisions, course_user.created_at
        ]

        add_assignments_info(csv, course_user)
      end
    end

    def add_assignments_info(csv, course_user)
      course_user.assignments.each do |assignment|
        csv << ['Assignment Title', 'Assignment URL', 'Role', 'Created At', 'Sandbox URL']
        csv << [
          assignment.article_title, assignment.article_url,
          assignment.role, assignment.created_at, assignment.sandbox_url
        ]
      end
    end

    def add_campaign_info(csv)
      @user.campaigns_users.includes(:campaign).each do |campaign_user|
        csv << ['Campaign', 'Joined At']
        csv << [campaign_user.campaign.slug, campaign_user.created_at]
      end
    end

    def add_lti_context_info(csv)
      contexts = LtiContext.where(user_id: @user.id)
      return if contexts.empty?

      # No name or email columns: the anonymized posture means the Dashboard
      # never receives LMS-supplied names or emails, and the columns that once
      # held them are gone from lti_contexts.
      contexts.each do |context|
        csv << ['LMS', 'LMS User ID', 'Roles (from LMS)', 'Membership Status (from LMS)',
                'Linked At']
        csv << [context.lms_family, context.user_lti_id,
                Array(context.roles).join(', '), context.lms_membership_status,
                context.linked_at]
      end
    end

    # Scholars & Scientists applications (Wiki Education Dashboard only), each
    # followed by its answers in form order. Staff notes are left out: they're
    # staff's working notes about the application, not data the user provided.
    def add_course_application_info(csv)
      CourseApplication.where(user: @user).includes(:course).find_each do |application|
        csv << ['Application', 'Status', 'Submitted At', 'Decided At']
        csv << [application.course.slug, application.status, application.created_at,
                application.decided_at]
        application_answers(application).each do |answer|
          csv << ['Question', 'Answer', 'Follow-up Question', 'Follow-up Answer']
          csv << [answer.question.question_text, answer.answer_text,
                  answer.question.follow_up_question_text.presence,
                  answer.follow_up_answer_text]
        end
      end
    end

    def application_answers(application)
      group_order = application.course.course_application_form&.question_group_ids || []
      application.answer_groups.includes(answers: :question).flat_map(&:answers).sort_by do |a|
        question = a.question
        [group_order.index(question.question_group_id) || group_order.size,
         question.question_group_id, question.position.to_i, question.id]
      end
    end
  end
end

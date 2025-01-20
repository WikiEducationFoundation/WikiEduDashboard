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
  end
end

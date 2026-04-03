# frozen_string_literal: true

class MailerPreviewsController < ApplicationController
  CATEGORIES = [
    {
      name: 'Course lifecycle',
      previews: %w[
        CourseSubmissionMailerPreview
        CourseApprovalMailerPreview
        CourseApprovalFollowupMailerPreview
        UnsubmittedCourseAlertMailerPreview
        EnrollmentReminderMailerPreview
        FirstEnrolledStudentAlertMailerPreview
        NoEnrolledStudentsAlertMailerPreview
        NewInstructorEnrollmentMailerPreview
      ]
    },
    {
      name: 'Instructor notifications',
      previews: %w[
        ActiveCourseMailerPreview
        TermRecapMailerPreview
        CourseAdviceMailerPreview
        EarlyEnrollmentMailerPreview
        InstructorNotificationPreview
      ]
    },
    {
      name: 'Training & compliance',
      previews: %w[
        UntrainedStudentsAlertMailerPreview
        OverdueTrainingAlertMailerPreview
        NoTaEnrolledAlertMailerPreview
      ]
    },
    {
      name: 'Content & quality alerts',
      previews: %w[
        DidYouKnowAlertMailerPreview
        HighQualityArticleAssignmentMailerPreview
        SuspectedPlagiarismMailerPreview
        AlertMailerPreview
      ]
    },
    {
      name: 'AI edit detection',
      previews: %w[
        AiEditAlertMailerPreview
      ]
    },
    {
      name: 'Administrative',
      previews: %w[
        TicketNotificationMailerPreview
        SurveyMailerPreview
        WikiEmailMailerPreview
        Fall2017CmuExperimentMailerPreview
      ]
    }
  ].freeze

  def index
    ActionMailer::Preview.all # triggers load_previews internally
    preview_map = ActionMailer::Preview.all.index_by(&:name)
    @categories = CATEGORIES.filter_map do |cat|
      found = cat[:previews].filter_map { |name| preview_map[name] }
      next if found.empty?
      { name: cat[:name], previews: found }
    end
  end
end

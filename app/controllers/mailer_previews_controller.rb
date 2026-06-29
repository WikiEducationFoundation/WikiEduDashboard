# frozen_string_literal: true

class MailerPreviewsController < ApplicationController
  CATEGORIES = [
    {
      name: 'Course messages for instructors',
      previews: %w[
        CourseApprovalMailerPreview
        CourseApprovalFollowupMailerPreview
        UnsubmittedCourseAlertMailerPreview
        NoEnrolledStudentsAlertMailerPreview
        NoTaEnrolledAlertMailerPreview
        FirstEnrolledStudentAlertMailerPreview
        UntrainedStudentsAlertMailerPreview
        ActiveCourseMailerPreview
        CourseAdviceMailerPreview
        TermRecapMailerPreview
        InstructorNotificationPreview
      ]
    },
    {
      name: 'Student action alerts for instructors',
      previews: %w[
        DidYouKnowAlertMailerPreview
        HighQualityArticleAssignmentMailerPreview
        SuspectedPlagiarismMailerPreview
        AiEditAlertMailerPreview
        ScholarsAiEditAlertMailerPreview
        BlockedStudentAlertMailerPreview
      ]
    },
    {
      name: 'Messages for students',
      previews: %w[
        EnrollmentReminderMailerPreview
        OverdueTrainingAlertMailerPreview
        WikiEmailMailerPreview
      ]
    },
    {
      name: 'Surveys',
      previews: %w[
        SurveyMailerPreview
      ]
    },
    {
      name: 'Messages for staff',
      previews: %w[
        CourseSubmissionMailerPreview
        NewInstructorEnrollmentMailerPreview
        EarlyEnrollmentMailerPreview
        TicketNotificationMailerPreview
        AlertMailerPreview
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

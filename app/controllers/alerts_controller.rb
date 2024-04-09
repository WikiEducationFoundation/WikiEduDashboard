# frozen_string_literal: true

class AlertsController < ApplicationController
  before_action :require_signed_in, only: [:create, :notify_instructors]
  before_action :require_admin_permissions, only: [:resolve, :notify_instructors]
  before_action :set_alert, only: [:resolve]
  ALERT_TYPES = {
    'NeedHelpAlert' => NeedHelpAlert,
    'BadWorkAlert' => BadWorkAlert,
    'ReviewRequestAlert' => ReviewRequestAlert
  }.freeze
  # Creates alerts based on parameters. Doesn't require admin permission.
  # Other type of alerts are created via the update cycle, not directly by users.
  def create
    ensure_alerts_are_enabled { return }

    alert_type = params[:alert_type]
    @alert = ALERT_TYPES[alert_type].new(alert_params.except(:alert_type))
    @alert.user = current_user
    # :target_user_id will be nil for the 'dashboard help' option
    set_default_target_user unless alert_params[:target_user_id]

    if @alert.save
      generate_ticket
      render json: {}, status: :ok
    else
      render json: { errors: @alert.errors, message: 'unable to create alert' },
             status: :internal_server_error
    end
  end

  # Resolves alert if it is resolvable? Requires admin permission.
  # Normally, same alerts won't be created for the second time.
  # Resolving alert, allows it to be created for the second time if conditions are met.
  def resolve
    ensure_alert_is_resolvable { return }

    @alert.update resolved: true

    render json: { alert: @alert }
  end

  # Create alert and send notification to all the instructors of a course.
  def notify_instructors
    unless params[:course_id].present? && params[:subject].present? && params[:message].present?
      render json: { error: 'course_id, subject, and message are required fields' },
             status: :bad_request
      return
    end

    @alert = build_instructor_notification_alert

    if save_and_notify_instructors
      render json: { alert: @alert }, status: :created
    else
      render json: { errors: @alert.errors, message: 'Unable to send notification to instructors' },
             status: :unprocessable_entity
    end
  end

  private

  def build_instructor_notification_alert
    InstructorNotificationAlert.new(
      course_id: params[:course_id],
      message: params[:message],
      user: current_user,
      subject: params[:subject]
    )
  end

  def save_and_notify_instructors
    if @alert.save
      @alert.send_email # send email to all instructors of the course_id
      true
    else
      false
    end
  end

  def generate_ticket
    TicketDispenser::Dispenser.call(
      content: @alert.message,
      details: {
        sender_email: @alert.user.email,
        subject: params[:alert_type]
      },
      project_id: @alert.course_id,
      owner_id: @alert.target_user_id,
      sender_id: @alert.user_id
    )
  end

  def ensure_alerts_are_enabled
    return if Features.enable_get_help_button?
    render json: {}, status: :bad_request
    yield
  end

  def ensure_alert_is_resolvable
    return if @alert.resolvable?
    render json: {}, status: :unprocessable_entity
    yield
  end

  def alert_params
    params.permit(:alert_type, :article_id, :course_id, :message, :target_user_id, :subject_id)
  end

  def set_default_target_user
    @alert.target_user_id = @alert.default_target_user&.id if @alert.is_a? ReviewRequestAlert
    @alert.target_user_id ||= SpecialUsers.technical_help_staff&.id
  end

  def set_alert
    @alert = Alert.find(params[:id])
  end
end

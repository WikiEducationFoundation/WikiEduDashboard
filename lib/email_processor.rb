# frozen_string_literal: true

# Handles incoming email via griddler, turning emails @dashboard.wikiedu.org forwarded by Mailgun
# into Tickets
class EmailProcessor
  def initialize(email)
    @email = email
    @content, @course, @from_address, @owner, @reference_id, @sender = nil
  end

  def process
    return false if email_can_be_ignored?
    define_owner
    define_sender
    define_course
    define_content_and_reference_id
    dispense_or_thread_ticket
  end

  def retrieve_original_sender_email
    raw_body = @email.raw_body
    expression = /\b[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}\b/i
    raw_body[expression]
  end

  def retrieve_course_slug_by_url
    raw_body = @email.raw_body
    expression = course_slug_pattern
    raw_body[expression]
  end

  private

  def email_can_be_ignored?
    @email.body.include?('ignore_creating_dashboard_ticket')
  end

  # This regex helps look for a course slug inside of text
  # (?<=\/courses\/) - Starts with `/courses/`
  # [^?\/\s] - Any non-whitespace character excluding a slash or question mark
  # \/ - A slash
  # [^?\/\s] - Any non-whitespace character excluding a slash or question mark
  def course_slug_pattern
    %r{(?<=/courses/)[^?/\s]+/[^?/\s]+}i
  end

  def define_owner
    recipient_emails = @email.to.pluck(:email)
    recipient_emails += @email.cc.pluck(:email) if @email.cc.present?
    @owner = User.find_by(greeter: true, email: recipient_emails)
  end

  def define_sender
    @from_address = @email.from[:email]
    if forwarded_from_staff?
      @original_from_address = retrieve_original_sender_email
      @sender = User.find_by(email: @original_from_address) unless @original_from_address.nil?
    elsif @from_address
      @sender = User.find_by(email: @from_address)
    end
  end

  def forwarded_from_staff?
    @from_address.end_with?(ENV['TICKET_FORWARDING_DOMAIN'])
  end

  def define_course
    @course = Course.find_by(slug: retrieve_course_slug_by_url)
    @course ||= @sender.courses.last if @sender
  end

  def define_content_and_reference_id
    @content = if forwarded_from_staff?
                 @email.raw_body
               else
                 @email.body
               end
    reference = @email.raw_body.match('ref_(.*)_ref')
    @reference_id = reference[1] if reference
  end

  def dispense_or_thread_ticket
    if @reference_id
      thread_ticket
    else
      create_ticket
    end
  rescue StandardError
    create_ticket
  end

  def create_ticket
    details = {
      subject: @email.subject,
      sender_email: @original_from_address || @from_address
    }
    details = { cc: @email.cc, **details } if @email.cc.present?
    TicketDispenser::Dispenser.call(
      content: @content,
      owner_id: @owner&.id,
      project_id: @course&.id,
      sender_id: @sender&.id,
      details:
    )
  end

  def thread_ticket
    details = {
      subject: @email.subject,
      sender_email: @from_address
    }
    details = { cc: @email.cc, **details } if @email.cc.present?
    TicketDispenser::Dispenser.thread(
      content: @content,
      reference_id: @reference_id,
      sender_id: @sender&.id,
      details:
    )
  end
end

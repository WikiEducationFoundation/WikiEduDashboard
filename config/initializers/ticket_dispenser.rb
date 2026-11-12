# frozen_string_literal: true

require 'ticket_dispenser'

# The engine's base controller uses `with: :null_session`, which doesn't stop
# a forged request here: the admin check happens in the router, before the
# session is blanked. Raise instead, as the app's controllers do. The tickets
# UI sends the CSRF token with every request.
Rails.application.config.to_prepare do
  TicketDispenser::ApplicationController.class_eval do
    protect_from_forgery with: :exception, prepend: true
  end
end

Rails.application.config.to_prepare do
  TicketDispenser::Ticket.class_eval do
    def sender
      message = messages.first
      return {} unless message

      user = message.sender if message
      return { email: message.details[:sender_email] } if user.nil?

      {
        username: user.username,
        real_name: user.real_name,
        email: user.email
      }.merge(sender_roles(user))
    end

    private

    # `role` matches User#highest_role, which counts admins as instructors.
    # `course_role` is the sender's actual role in the course, or nil if they
    # aren't in it. Both come from a single query.
    def sender_roles(user)
      course_role = user.course_roles(project).first
      role = if user.admin?
               CoursesUsers::Roles::INSTRUCTOR_ROLE
             else
               course_role || CoursesUsers::Roles::VISITOR_ROLE
             end
      { role:, course_role: }
    end
  end
end

Rails.application.config.to_prepare do
  TicketDispenser::Message.class_eval do
    # Fix Rails 7.2 serialize syntax for TicketDispenser gem
    serialize :details, type: Hash

    def serialized_sender
      return {} if sender.nil?
      {
        sender_id: sender_id,
        real_name: sender.real_name
      }
    end
  end
end

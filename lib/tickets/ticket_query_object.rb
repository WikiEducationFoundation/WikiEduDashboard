# frozen_string_literal: true

class TicketQueryObject
  def initialize(params)
    @whats = {
      by_email_or_username: params[:by_email_or_username],
      in_subject: params[:in_subject],
      in_content: params[:in_content],
      by_course: params[:by_course]
    }
    @whats.delete_if { |_, value| value.nil? || value.empty? }
    @offset = params[:offset] || 0
    @limit = params[:limit] || 100
  end

  def search
    query = tickets

    @whats.each do |key, value|
      case key
      when :by_email_or_username
        query = query.merge(search_by_username_or_by_email(value))
      when :in_subject
        query = query.merge(search_by_subject(value))
      when :in_content
        query = query.merge(search_by_content(value))
      when :by_course
        query = query.merge(search_by_course(value))
      end
    end

    query.offset(@offset).limit(@limit)
  end

  def search_by_username_or_by_email(search_text)
    sender_usernames = User.where(username: search_text)
                           .or(User.where(email: search_text))
                           .pluck(:username)
    tickets.where(sender: { username: sender_usernames })
  end

  def search_by_content(search_text)
    message_ids = TicketDispenser::Message.where('content LIKE ?', "%#{search_text}%").pluck(:id)
    tickets.where(messages: { id: message_ids })
  end

  def search_by_subject(search_text)
    message_ids = TicketDispenser::Message.all.select do |ticket|
      ticket[:details][:subject]&.match?(/#{search_text}/i)
    end.pluck(:id)
    tickets.where(messages: { id: message_ids })
  end

  def search_by_course(search_text)
    course = Course.find_by(slug: search_text)
    tickets.where(project: course)
  end

  private

  def tickets
    TicketDispenser::Ticket.all
                           .includes(:project, :owner, messages: :sender)
  end
end

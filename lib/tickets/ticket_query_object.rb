# frozen_string_literal: true

class TicketQueryObject
  def initialize(params)
    @search = params[:search]
    @whats = params[:what]
    @offset = params[:offset] || 0
    @limit = params[:limit] || 100
  end

  def search
    query = tickets

    @whats.each do |what|
      case what
      when 'by_email_or_username'
        query = query.merge(search_by_username_or_by_email)
      when 'in_subject'
        query = query.merge(search_by_subject)
      when 'in_content'
        query = query.merge(search_by_content)
      when 'by_course'
        query = query.merge(search_by_course)
      end
    end

    query.offset(@offset).limit(@limit)
  end

  def search_by_username_or_by_email
    sender_usernames = User.where(username: @search).or(User.where(email: @search)).pluck(:username)
    tickets.where(sender: { username: sender_usernames })
  end

  def search_by_content
    message_ids = TicketDispenser::Message.where('content LIKE ?', "%#{@search}%").pluck(:id)
    tickets.where(messages: { id: message_ids })
  end

  def search_by_subject
    message_ids = TicketDispenser::Message.all.select do |ticket|
      ticket[:details][:subject]&.match?(/#{@search}/i)
    end.pluck(:id)
    tickets.where(messages: { id: message_ids })
  end

  def search_by_course
    course = Course.find_by(slug: @search)
    tickets.where(project: course)
  end

  private

  def tickets
    TicketDispenser::Ticket.all
                           .includes(:project, :owner, messages: :sender)
  end
end

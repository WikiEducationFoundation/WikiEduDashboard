# frozen_string_literal: true

class TicketQueryObject
  def initialize(params)
    @search = params[:search]
    @what = params[:what]
    @offset = params[:offset] || 0
    @limit = params[:limit] || 100
  end

  def search
    case @what
    when 'by_email_or_username'
      search_by_username_or_by_email
    when 'in_subject'
      search_by_subject
    when 'in_content'
      search_by_content
    end
  end

  def search_by_username_or_by_email
    tickets.where(sender:
                  { username:
                    User.where(username: @search).or(User.where(email: @search))
      .pluck(:username) })
           .offset(@offset)
           .limit(@limit)
  end

  def search_by_content
    tickets.where(messages:
                  { id:
                    TicketDispenser::Message.where('content LIKE ?', "%#{@search}%")
      .pluck(:id) })
           .offset(@offset)
           .limit(@limit)
  end

  def search_by_subject
    tickets.where(messages:
                  { id:
                    TicketDispenser::Message
      .all
      .select do |ticket|
        ticket[:details][:subject]&.match?(/#{@search}/i)
      end
        .pluck(:id) })
           .offset(@offset)
           .limit(@limit)
  end

  private

  def tickets
    TicketDispenser::Ticket.all
                           .includes(:project, :owner, messages: :sender)
  end
end

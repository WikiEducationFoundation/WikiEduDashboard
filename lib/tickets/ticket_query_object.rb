# frozen_string_literal: true

class TicketQueryObject
  def initialize(params)
    # @current_user = current_user
    @search = params[:query]
    @offset = params[:offset] || 0
    @limit = params[:limit] || 100
  end

  def search_by_username_or_by_email
    srch = "%#{@search}%"
    TicketDispenser::Ticket.all
                           .includes(:project, :owner, messages: :sender)
                           .where(sender:
                                  { username:
                                    User.where('username LIKE ? OR email LIKE ?', srch, srch)
                                        .pluck(:username) })
                           .offset(@offset)
                           .limit(@limit)
  end
end

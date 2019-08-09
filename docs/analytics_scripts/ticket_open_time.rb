CSV.open("/home/sage/ticket_status.csv", 'wb') do |csv|
  csv << ['opened', 'updated', 'time_difference', 'status', 'message_count', 'owner']
  TicketDispenser::Ticket.all.includes(:owner).each do |ticket|
    csv << [ticket.created_at, ticket.updated_at, ticket.updated_at - ticket.created_at, ticket.status, ticket.messages.count, ticket.owner&.username]
  end
end


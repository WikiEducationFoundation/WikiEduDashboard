# frozen_string_literal: true

json.tickets do
  json.array! @tickets do |ticket|
    json.id ticket.id
    json.status ticket.status
    json.sender do
      json.username ticket.sender[:username]
      json.real_name ticket.sender[:real_name]
      json.email ticket.sender[:email]
      json.role ticket.sender[:role]
    end
    json.owner do
      json.id ticket.owner&.id
      json.username ticket.owner&.username
      json.real_name ticket.owner&.real_name
    end
    json.project do
      json.id ticket.project&.id
      json.title ticket.project&.title
      json.slug ticket.project&.slug
    end
    json.read ticket.read
    json.messages do
      json.array! ticket.messages do |message|
        json.content message.content
        json.id message.id
        json.kind message.kind
        json.read message.read
        json.sender do
          json.sender_id message.sender_id
          json.real_name message.sender&.real_name
        end
        json.details message.details
        json.created_at message.created_at
        json.updated_at message.updated_at
      end
    end
    json.subject ticket.subject
    json.sender_email ticket.sender_email
  end
end

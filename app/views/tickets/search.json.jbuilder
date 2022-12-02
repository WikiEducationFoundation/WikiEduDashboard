# frozen_string_literal: true

json.tickets do
  json.array! @tickets do |ticket|
    json.id ticket.id
    json.status ticket.status
    json.sender do
      json.username ticket.sender[:username]
      json.real_name ticket.sender[:real_name]
      json.email ticket.sender[:email]
    end
    json.owner do
      json.id ticket.owner.id
      json.username ticket.owner.username
      json.real_name ticket.owner.real_name
    end
    json.project do
      json.id ticket.project.id
      json.title ticket.project.title
      json.slug ticket.project.slug
    end
    json.messages do
      json.array! ticket.messages do |message|
        json.message message
      end
    end
    json.subject ticket.subject
    json.sender_email ticket.sender_email
  end
end

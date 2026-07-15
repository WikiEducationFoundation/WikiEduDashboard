# frozen_string_literal: true

# The saved response, so the SPA can transition to the submitted view.
json.response do
  json.partial! 'response', response: @response
end

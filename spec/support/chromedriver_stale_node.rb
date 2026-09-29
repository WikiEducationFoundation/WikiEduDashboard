# frozen_string_literal: true

# Capybara retries a query when an element it found goes stale (e.g. React
# re-renders it mid-check), by rescuing StaleElementReferenceError. Newer
# chromedriver releases (seen on CI with Chrome 152) sometimes report that same
# situation as a generic UnknownError, "unhandled inspector error: ... Node with
# given id does not belong to the document", which Capybara does not retry, so
# the example fails at once instead of re-running the query. Treat that
# message as the stale element it is.
module RetryChromedriverDetachedNode
  DETACHED_NODE_MESSAGE = 'Node with given id does not belong to the document'

  private

  def catch_error?(error, errors = nil)
    if error.is_a?(Selenium::WebDriver::Error::UnknownError) &&
       error.message.include?(DETACHED_NODE_MESSAGE)
      error = Selenium::WebDriver::Error::StaleElementReferenceError.new(error.message)
    end
    super
  end
end

Capybara::Node::Base.prepend RetryChromedriverDetachedNode

# frozen_string_literal: true

# Raised by RetentionStudentStats and RetentionParticipantHistory when a
# usercontribs request gives no answer. WikiApi has already retried it and
# logged the failure; what matters here is that a student whose edits could not
# be fetched is not reported (or, worse, stored) as somebody who never edited.
class RetentionFetchError < StandardError
  def initialize(username, wiki)
    super("Could not fetch #{username}'s contributions from #{wiki.domain}")
  end
end

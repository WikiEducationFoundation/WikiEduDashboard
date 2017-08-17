# frozen_string_literal: true

class BlockedEditsAlert < Alert
  def main_subject
    "Edit by #{user.username} was blocked"
  end

  def url
    user_profile_url
  end
end

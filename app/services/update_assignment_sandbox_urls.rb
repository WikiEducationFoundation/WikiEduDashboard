# frozen_string_literal: true

class UpdateAssignmentSandboxUrls
  def initialize(user)
    @user = user
    # saved_change_to_username is a Rails Dirty method that returns [old, new]
    # values for the username attribute after it has been saved to the database.
    # https://api.rubyonrails.org/classes/ActiveRecord/AttributeMethods/Dirty.html#method-i-saved_change_to_attribute
    # We use a fallback to saved_changes[:username] for extra robustness.
    @old_username, @new_username = user.saved_change_to_username || user.saved_changes[:username]
  end

  def update
    return unless @old_username && @new_username

    # We search globally for any assignments whose sandbox_url matches the old
    # username's userspace pattern. This handles group assignments more reliably
    # and ensures we don't miss assignments in courses where the user isn't joining records.
    Assignment.where('sandbox_url LIKE ?', "%User:#{@old_username}/%").each do |assignment|
      # 1. Safety Guard: Only update if the current URL matches the default pattern
      # for the old username. This ensures we don't overwrite manual customizations.
      expected_old_url = assignment.default_sandbox_url(@old_username)
      expected_old_url += "/#{assignment.user.username}_Peer_Review" if assignment.reviewing?
      next unless assignment.sandbox_url == expected_old_url

      # 2. Existence Check: Only update if the sandbox has not been created on the wiki yet.
      # If work has already started on ANY related sandbox (draft, bibliography, outline,
      # or peer review), we skip the update to avoid disrupting the user's workflow or links.
      status_checks = [
        assignment.draft_sandbox_status,
        assignment.bibliography_sandbox_status,
        assignment.outline_sandbox_status,
        assignment.peer_review_sandbox_status
      ]
      next if status_checks.any? { |status| status != 'does_not_exist' }

      # 3. Apply the update using the new username's default pattern.
      new_url = assignment.default_sandbox_url(@new_username)
      new_url += "/#{assignment.user.username}_Peer_Review" if assignment.reviewing?
      assignment.update(sandbox_url: new_url)
    end
  end
end

# frozen_string_literal: true

# == Schema Information
#
# Table name: alerts
#
#  id             :integer          not null, primary key
#  course_id      :integer
#  user_id        :integer
#  article_id     :integer
#  revision_id    :integer
#  type           :string(255)
#  email_sent_at  :datetime
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  message        :text(65535)
#  target_user_id :integer
#  subject_id     :integer
#  resolved       :boolean          default(FALSE)
#  details        :text(65535)
#

# Alert indicating that the Dashboard's IP may be blocked.
# The #details hold the API error response that triggered the alert, like this:
# { "error" => {"code"=>"blocked",
#   "info"=>"You have been blocked from editing.",
#   "blockinfo"=>
#    {"blockid"=>17605815,
#     "blockedby"=>"Blablubbs",
#     "blockedbyid"=>22922645,
#     "blockreason"=>"{{Colocationwebhost}} <!-- Linode -->",
#     "blockedtimestamp"=>"2023-01-07T12:40:30Z",
#     "blockexpiry"=>"2025-02-07T12:40:30Z",
#     "blocknocreate"=>"",
#     "blockedtimestampformatted"=>"12:40, 7 January 2023",
#     "blockexpiryformatted"=>"12:40, 7 February 2025",
#     "blockexpiryrelative"=>"in 2 years"},
#   "*"=>
#    "See https://en.wikipedia.org/w/api.php for API usage. Subscribe to the
#     mediawiki-api-announce mailing list at &lt;
#     https://lists.wikimedia.org/postorius/lists/mediawiki-api-announce.lists.wikimedia.org/&gt;
#     for notice of API deprecations and breaking changes." }}
# The #details may also include a top-level 'wiki_domain' key with the domain of
# the wiki where the blocked edit was attempted.
class BlockedEditsAlert < Alert
  def main_subject
    "Edit by #{user.username} was blocked"
  end

  def url
    user_profile_url
  end

  def message
    ticket_body
  end

  def ticket_body
    <<~BLOCK_DETAILS
      An automatic Dashboard edit was blocked. This may mean the Dashboard's IP address is
      being affected by a range block. (No additional alerts for subsequent blocked edits
      will be generated for 8 hours.)

      This typically requires an adjustment of the block; changing the block to anon-only
      will allow the Dashboard to make edits normally. Contact the blocking admin to request
      a block adjustment.

      Block details: #{block_log_url}

      Blocking user talk page: #{blocked_by_talk_page}

      Wiki: #{wiki_domain}

      Affected user: #{user.username}

      Info: #{details}
    BLOCK_DETAILS
  end

  private

  def block_id
    details.dig('error', 'blockinfo', 'blockid')
  end

  def error_code
    details.dig('error', 'code')
  end

  def error_info
    details.dig('error', 'info').to_s
  end

  # Global blocks may arrive with the generic 'blocked' error code, so we also
  # sniff the info text for the '[[m:Special:MyLanguage/Global blocks|...]]'
  # link target, which stays intact in translated versions of the message.
  def global_block?
    error_code.to_s.include?('globalblocking') || error_info.include?('Global blocks')
  end

  def wiki_domain
    details['wiki_domain'] || 'en.wikipedia.org'
  end

  # Global blocks live in a shared table; Meta is their canonical home, and
  # local block IDs are only meaningful on the wiki where the edit was blocked.
  def block_log_url
    if global_block?
      "https://meta.wikimedia.org/wiki/Special:GlobalBlockList?target=%23#{block_id}"
    else
      "https://#{wiki_domain}/wiki/Special:BlockList?wpTarget=%23#{block_id}"
    end
  end

  def blocked_by
    details.dig('error', 'blockinfo', 'blockedby')
  end

  # Global blocks are made by stewards, whose talk pages are on Meta.
  def blocked_by_talk_page
    domain = global_block? ? 'meta.wikimedia.org' : wiki_domain
    "https://#{domain}/wiki/User_talk:#{blocked_by&.tr(' ', '_')}"
  end
end

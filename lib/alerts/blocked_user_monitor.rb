# frozen_string_literal: true

# This class checks recent block logs and creates alerts
# for any active Dashboard users who were blocked.
class BlockedUserMonitor
  def self.create_alerts_for_recently_blocked_users
    new.create_alerts_for_recently_blocked_users
  end

  def initialize
    @wiki = Wiki.find_by(language: 'en', project: 'wikipedia')
  end

  def create_alerts_for_recently_blocked_users
    blocked_dashboard_users.each do |user|
      recent_blocks.each do |block|
        next unless blocked_username(block) == user.username
        next if alert_exists?(block, user)
        create_alert_and_send_email(block, user)
      end
    end
  end

  private

  # The most recent 500 block logs on English Wikipedia will
  # typically cover more than a full day, so there's no
  # need do multiple requests with continuation.
  BLOCK_LOG_QUERY = {
    list: 'logevents',
    letype: 'block',
    lelimit: 500
  }.freeze
  # Each block log in the data looks like this:
  # {"logid"=>92646315,
  #   "ns"=>2,
  #   "title"=>"User:Thicccgurl",
  #   "pageid"=>0,
  #   "logpage"=>0,
  #   "params"=>{"duration"=>"infinite", "flags"=>["nocreate"]},
  #   "type"=>"block",
  #   "action"=>"block",
  #   "user"=>"Hut 8.5",
  #   "timestamp"=>"2018-08-21T21:06:59Z",
  #   "comment"=>"[[WP:Vandalism-only account|Vandalism-only account]]"}
  def recent_blocks
    @recent_blocks_response ||= WikiApi.new(@wiki).query BLOCK_LOG_QUERY
    @recent_blocks_response.data['logevents']
  end

  def blocked_usernames
    recent_blocks.map { |block| blocked_username(block) }
  end

  def blocked_dashboard_users
    User.where(username: blocked_usernames)
  end

  def blocked_username(block)
    block['title']&.gsub('User:', '')
  end

  def alert_exists?(block, user)
    BlockedUserAlert.exists?(user: user, details: block)
  end

  def create_alert_and_send_email(block, user)
    BlockedUserAlert
      .create(user: user, details: block, course: user.courses.last)
      .email_content_expert
  end
end

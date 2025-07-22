# frozen_string_literal: true

# Ad-hoc back-filling of registered_at attribute for users who don't return
# a registration date from Meta userinfo.

User.where(registered_at: nil).each do |user|
  course = user.courses.first
  unless course
    puts user.username
    next
  end
  wiki = user.courses.first.home_wiki
  user_info = WikiApi.new(wiki).get_user_info(user.username)
  registration = user_info['registration']
  user.registered_at = registration
  user.save
end

wiki = Wiki.find_by(language: 'en', project: 'wikipedia')
User.where(registered_at: nil).each do |user|
  user_info = WikiApi.new(wiki).get_user_info(user.username)
  registration = user_info['registration']
  user.registered_at = registration
  user.save
end

User.where(registered_at: nil).each do |user|
  rev = user.revisions.first
  next unless rev
  query = { prop: 'revisions',
            revids: rev.mw_rev_id }
  data = WikiApi.new(rev.wiki).query(query).data
  username = data.dig('pages', rev.mw_page_id.to_s, 'revisions')[0]['user']
  user.username = username
  begin
    user.save
  rescue
    pp user.id
    pp user.username
  end
end

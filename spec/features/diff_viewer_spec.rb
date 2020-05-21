# frozen_string_literal: true

require 'rails_helper'
require "#{Rails.root}/lib/replica"

describe 'diff viewer', type: :feature, js: true do
  let(:en_wiki) { Wiki.get_or_create(language: 'en', project: 'wikipedia') }
  let(:course) { create(:course, id: 1, start: '2013-01-01', end: '2014-01-02') }
  let(:user) { create(:user, id: 1, username: 'I enjoy sandwiches') }
  let(:article) do
    create(:article, id: 1, title: 'Periodontium', mw_page_id: 1172296, rating: 'fa')
  end

  it 'checks whether diff viewer is working properly' do
    VCR.use_cassette 'diff_viewer/revisions' do
      login_as user
      all_users = [
        build(:user, username: 'I enjoy sandwiches')
      ]
      rev_start = 2016_04_17_003430
      rev_end = 2016_04_18_003430

      response = Replica.new(en_wiki).get_revisions(all_users, rev_start, rev_end)

      response[article.mw_page_id.to_s]['revisions'].each_with_index do |revision, index|
        create(:revision,
               id: index,
               mw_rev_id: revision['mw_rev_id'],
               date: revision['date'],
               characters: revision['characters'].to_i,
               wiki_id: revision['wiki_id'],
               article_id: article.id,
               new_article: revision['new_article'],
               system: revision['system'],
               deleted: false,
               user_id: user.id)
      rescue ActiveRecord::RecordNotUnique
        next
      end

      create(:courses_user, id: 1, course_id: 1, user_id: 1)
      create(:articles_course, id: 1, course: course, article: article, tracked: true)

      visit "/courses/#{Course.first.slug}/activity"

      expect(page).to have_css('button.icon-diff-viewer', count: 3)
      all('button.icon-diff-viewer').last.click
      expect(page).to have_content 'Edited on 2016/04/17 9:16 pm; -69 Chars Added'
    end
  end
end

# frozen_string_literal: true

require 'rails_helper'
require "#{Rails.root}/lib/cumulative_diff_url_builder"

describe CumulativeDiffUrlBuilder do
  let(:article) { create(:article) }
  let(:course) { create(:course, start: '2024-06-16', end: '2024-08-16') }
  let(:user1) { create(:user, username: 'StudentA') }
  let(:user2) { create(:user, username: 'StudentB') }
  let(:articles_course) do
    create(:articles_course, article:, course:, user_ids: [user1.id, user2.id])
  end

  before do
    travel_to Date.new(2024, 7, 16)
  end

  after do
    travel_back
  end

  describe '#url' do
    context 'when both users have revisions' do
      before do
        allow_any_instance_of(WikiApi).to receive(:query).and_wrap_original do |_m, params|
          response = instance_double(MediawikiApi::Response)
          allow(response).to receive(:data).and_return(
            build_response(params[:rvuser], params[:rvdir])
          )
          response
        end
      end

      it 'returns a diff URL from the earliest first revision to the latest last revision' do
        url = articles_course.cumulative_diff_url
        # StudentA's earliest has parentid 99, StudentB's latest has revid 504
        expect(url).to eq("https://en.wikipedia.org/w/index.php?oldid=99&diff=504")
      end
    end

    context 'when the first revision created the article (parentid 0)' do
      before do
        allow_any_instance_of(WikiApi).to receive(:query).and_wrap_original do |_m, params|
          response = instance_double(MediawikiApi::Response)
          allow(response).to receive(:data).and_return(
            build_new_article_response(params[:rvdir])
          )
          response
        end
      end

      it 'uses the first revid instead of parentid 0' do
        url = articles_course.cumulative_diff_url
        # parentid is 0, so oldid should be the first revid (100) not 0
        expect(url).to eq("https://en.wikipedia.org/w/index.php?oldid=100&diff=102")
      end
    end

    context 'when no users have revisions' do
      before do
        allow_any_instance_of(WikiApi).to receive(:query).and_return(nil)
      end

      it 'returns nil' do
        expect(articles_course.cumulative_diff_url).to be_nil
      end
    end

    context 'when only one user has revisions' do
      before do
        allow_any_instance_of(WikiApi).to receive(:query).and_wrap_original do |_m, params|
          next unless params[:rvuser] == 'StudentA'
          response = instance_double(MediawikiApi::Response)
          allow(response).to receive(:data).and_return(
            build_single_user_response(params[:rvdir])
          )
          response
        end
      end

      it 'returns a diff URL using that single user revisions' do
        url = articles_course.cumulative_diff_url
        expect(url).to eq("https://en.wikipedia.org/w/index.php?oldid=99&diff=102")
      end
    end

    context 'when user_ids is empty' do
      let(:articles_course) do
        create(:articles_course, article:, course:, user_ids: [])
      end

      it 'returns nil' do
        expect(articles_course.cumulative_diff_url).to be_nil
      end
    end

    context 'when the API returns a page with no revisions' do
      before do
        allow_any_instance_of(WikiApi).to receive(:query) do
          response = instance_double(MediawikiApi::Response)
          allow(response).to receive(:data).and_return(
            { 'pages' => { '-1' => { 'ns' => 0, 'title' => 'Nonexistent', 'missing' => '' } } }
          )
          response
        end
      end

      it 'returns nil' do
        expect(articles_course.cumulative_diff_url).to be_nil
      end
    end
  end

  # StudentA: earliest rev at July 1 (parentid 99, revid 100), latest at July 10 (revid 102)
  # StudentB: earliest rev at July 5 (parentid 200, revid 201), latest at July 15 (revid 504)
  def build_response(username, direction)
    revisions = {
      'StudentA' => {
        'newer' => { 'revid' => 100, 'parentid' => 99, 'timestamp' => '2024-07-01T12:00:00Z',
                     'user' => 'StudentA' },
        'older' => { 'revid' => 102, 'parentid' => 101, 'timestamp' => '2024-07-10T12:00:00Z',
                     'user' => 'StudentA' }
      },
      'StudentB' => {
        'newer' => { 'revid' => 201, 'parentid' => 200, 'timestamp' => '2024-07-05T12:00:00Z',
                     'user' => 'StudentB' },
        'older' => { 'revid' => 504, 'parentid' => 503, 'timestamp' => '2024-07-15T12:00:00Z',
                     'user' => 'StudentB' }
      }
    }

    rev = revisions.dig(username, direction)
    { 'pages' => { '1' => { 'pageid' => 1, 'revisions' => [rev] } } }
  end

  # New article: parentid is 0 (student created the page)
  def build_new_article_response(direction)
    revisions = {
      'newer' => { 'revid' => 100, 'parentid' => 0, 'timestamp' => '2024-07-01T12:00:00Z',
                   'user' => 'StudentA' },
      'older' => { 'revid' => 102, 'parentid' => 101, 'timestamp' => '2024-07-10T12:00:00Z',
                   'user' => 'StudentA' }
    }

    rev = revisions[direction]
    { 'pages' => { '1' => { 'pageid' => 1, 'revisions' => [rev] } } }
  end

  def build_single_user_response(direction)
    revisions = {
      'newer' => { 'revid' => 100, 'parentid' => 99, 'timestamp' => '2024-07-01T12:00:00Z',
                   'user' => 'StudentA' },
      'older' => { 'revid' => 102, 'parentid' => 101, 'timestamp' => '2024-07-10T12:00:00Z',
                   'user' => 'StudentA' }
    }

    rev = revisions[direction]
    { 'pages' => { '1' => { 'pageid' => 1, 'revisions' => [rev] } } }
  end
end

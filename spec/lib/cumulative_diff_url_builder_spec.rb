# frozen_string_literal: true

require 'rails_helper'
require "#{Rails.root}/lib/cumulative_diff_url_builder"

# Examples in this spec use real users, articles, and dates from this ended course:
# https://dashboard.wikiedu.org/courses/Aquinas_College/Advanced_Communication_Theory_(Fall_2025)
# (start: 2025-08-18, end: 2025-12-10)
describe CumulativeDiffUrlBuilder do
  let(:course) { create(:course, start: '2025-08-18', end: '2025-12-10') }

  describe '#url' do
    context 'when both editors contributed to the article' do
      # "Media multiplexity theory" was edited by two students from the course:
      # - Kfase   (earliest, 2025-09-08, revid 1310268231 / parentid 1291883584)
      # - JakeZim16 (latest, 2025-11-18, revid 1322934870 / parentid 1310268231)
      let(:article) { create(:article, title: 'Media_multiplexity_theory') }
      let(:kfase) { create(:user, username: 'Kfase') }
      let(:jakezim) { create(:user, username: 'JakeZim16') }
      let(:articles_course) do
        create(:articles_course, article:, course:, user_ids: [kfase.id, jakezim.id])
      end

      it 'returns a diff URL from the earliest first revision to the latest last revision' do
        VCR.use_cassette 'cached/cumulative_diff_url_builder/both_editors' do
          expect(articles_course.cumulative_diff_url)
            .to eq('https://en.wikipedia.org/w/index.php?oldid=1291883584&diff=1322934870')
        end
      end
    end

    context 'when only one user has revisions' do
      # "Social constructionism" was edited only by Nateiac7 in the course window
      # (earliest 2025-11-17 parentid 1316523874, latest 2025-11-19 revid 1323073695).
      # Julia.kennedy2004 is in the course but did not edit this article.
      let(:article) { create(:article, title: 'Social_constructionism') }
      let(:editor) { create(:user, username: 'Nateiac7') }
      let(:non_editor) { create(:user, username: 'Julia.kennedy2004') }
      let(:articles_course) do
        create(:articles_course, article:, course:, user_ids: [editor.id, non_editor.id])
      end

      it 'returns a diff URL using that single user revisions' do
        VCR.use_cassette 'cached/cumulative_diff_url_builder/single_editor' do
          expect(articles_course.cumulative_diff_url)
            .to eq('https://en.wikipedia.org/w/index.php?oldid=1316523874&diff=1323073695')
        end
      end
    end

    context 'when the first revision created the article (parentid 0)' do
      # "User:JakeZim16/Media multiplexity theory" was created by JakeZim16
      # on 2025-10-19 (revid 1317703640, parentid 0). The latest revision in
      # the course window is revid 1322930411.
      let(:article) do
        create(:article,
               title: 'JakeZim16/Media_multiplexity_theory',
               namespace: Article::Namespaces::USER)
      end
      let(:user) { create(:user, username: 'JakeZim16') }
      let(:articles_course) do
        create(:articles_course, article:, course:, user_ids: [user.id])
      end

      it 'uses the first revid instead of parentid 0' do
        VCR.use_cassette 'cached/cumulative_diff_url_builder/new_article' do
          expect(articles_course.cumulative_diff_url)
            .to eq('https://en.wikipedia.org/w/index.php?oldid=1317703640&diff=1322930411')
        end
      end
    end

    context 'when user_ids is empty' do
      let(:article) { create(:article, title: 'Social_constructionism') }
      let(:articles_course) do
        create(:articles_course, article:, course:, user_ids: [])
      end

      it 'returns nil without making any API calls' do
        # No cassette needed: the builder short-circuits when user_ids is empty.
        expect(articles_course.cumulative_diff_url).to be_nil
      end
    end

    context 'when none of the users have revisions to the article in the course window' do
      # "Social constructionism" was not edited by Julia.kennedy2004 in the
      # course window, so the API returns the page with no revisions key.
      let(:article) { create(:article, title: 'Social_constructionism') }
      let(:non_editor) { create(:user, username: 'Julia.kennedy2004') }
      let(:articles_course) do
        create(:articles_course, article:, course:, user_ids: [non_editor.id])
      end

      it 'returns nil' do
        VCR.use_cassette 'cached/cumulative_diff_url_builder/no_revisions' do
          expect(articles_course.cumulative_diff_url).to be_nil
        end
      end
    end

    context 'when the WikiApi request fails (returns nil after retries)' do
      # Stubbed rather than recorded: WikiApi#query returns nil when its
      # underlying retries are exhausted on a network error. That path is
      # awkward to capture cleanly with VCR, so this one context keeps a
      # small stub for the failure case.
      let(:article) { create(:article, title: 'Social_constructionism') }
      let(:user) { create(:user, username: 'Nateiac7') }
      let(:articles_course) do
        create(:articles_course, article:, course:, user_ids: [user.id])
      end

      before do
        allow_any_instance_of(WikiApi).to receive(:query).and_return(nil)
      end

      it 'returns nil' do
        expect(articles_course.cumulative_diff_url).to be_nil
      end
    end
  end
end

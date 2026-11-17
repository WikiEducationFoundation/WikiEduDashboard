# frozen_string_literal: true

require_dependency "#{Rails.root}/lib/article_auditing/check"

module ArticleAuditing
  module Checks
    # Links to social media, retail and user-generated sites in the External
    # links and Further reading sections (WP:ELNO). Citations are left to the
    # source reliability check.
    class InappropriateExternalLinks < Check
      KEY = 'links.inappropriate_external_links'
      CATEGORY = 'links'
      MAX_FINDINGS = 10

      LINK_SECTIONS = ['external links', 'further reading'].freeze
      DOMAINS = %w[
        facebook.com instagram.com twitter.com x.com tiktok.com linkedin.com pinterest.com
        threads.net snapchat.com reddit.com tumblr.com
        amazon.com amazon.co.uk ebay.com etsy.com
        blogspot.com wordpress.com medium.com substack.com change.org gofundme.com
      ].freeze
      URL = %r{(?:https?:)?//(?:www\.|m\.)?([a-z0-9.-]+\.[a-z]{2,})[^\s\]|<\}]*}i

      def run(context)
        findings = link_sections(context.parsed_wikitext).flat_map do |section|
          section.body.to_enum(:scan, URL).filter_map do
            match = Regexp.last_match
            next unless flagged_domain?(match[1].downcase)
            finding(severity: 'should_fix', **coded(:flagged_link, domain: match[1].downcase),
                    section: section.title, quote: match[0], policy_refs: %w[WP:ELNO WP:ELMIN])
          end
        end
        output(findings.first(MAX_FINDINGS))
      end

      private

      def link_sections(wikitext)
        wikitext.headings.select { |section| LINK_SECTIONS.include?(section.title.downcase) }
      end

      def flagged_domain?(host)
        DOMAINS.any? { |domain| host == domain || host.end_with?(".#{domain}") }
      end
    end
  end
end

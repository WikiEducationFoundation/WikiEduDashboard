# frozen_string_literal: true

require_dependency "#{Rails.root}/lib/article_auditing/check"

module ArticleAuditing
  module Checks
    # A species article using the manual {{Taxobox}}. Recommends {{Speciesbox}}
    # when the genus's taxonomy template exists, and otherwise says that the
    # taxonomy template has to be created first.
    class Speciesbox < Check
      KEY = 'infobox.speciesbox'
      CATEGORY = 'infobox'

      TAXOBOX = /\Ataxobox\z/i

      def applies_to?(context)
        context.parsed_wikitext.templates(TAXOBOX).any?
      end

      def run(context)
        _, taxobox = context.parsed_wikitext.templates(TAXOBOX).first
        genus, species = genus_and_species(taxobox)
        return output([]) if genus.nil? || species.nil?
        taxonomy_template = "Template:Taxonomy/#{genus}"
        exists = context.wiki_context.existing_titles([taxonomy_template]).key?(taxonomy_template)
        output([exists ? use_speciesbox(genus, species) : needs_taxonomy(genus)])
      end

      private

      # From binomial = ''Genus species'', or the genus and species params.
      def genus_and_species(taxobox)
        binomial = param(taxobox, 'binomial')
        return binomial.split(/\s+/, 2) if binomial&.match?(/\A[A-Z][a-z]+ [a-z-]+\z/)
        genus = param(taxobox, 'genus')
        species = param(taxobox, 'species')&.split&.last
        [genus, species] if genus&.match?(/\A[A-Z][a-z]+\z/)
      end

      def param(template, name)
        value = template[/\|\s*#{name}\s*=\s*([^|}\n]*)/, 1]
        value&.gsub(/'{2,}|\[\[|\]\]/, '')&.strip.presence
      end

      def use_speciesbox(genus, species)
        finding(severity: 'suggestion', **coded(:use_speciesbox),
                suggestion: "{{Speciesbox\n| genus = #{genus}\n| species = #{species}\n}}",
                policy_refs: %w[WP:AUTOTAX])
      end

      def needs_taxonomy(genus)
        finding(severity: 'info', **coded(:needs_taxonomy_template, genus:),
                policy_refs: %w[WP:AUTOTAX])
      end
    end
  end
end

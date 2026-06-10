# frozen_string_literal: true

require "#{Rails.root}/lib/source_verification_example_store"

# Harvests (claim, cited source) examples into the prototype example store.
# Examples:
#   rake source_verification:harvest_articles TITLES="Third place;Selfie"
#   rake source_verification:harvest_articles TITLES="Berlin" LANGUAGE=de
#   rake source_verification:harvest_course COURSE=school/course_(term) MAX_EXAMPLES=10
namespace :source_verification do
  desc 'Harvest claim/source examples from articles (TITLES, semicolon-separated)'
  task harvest_articles: :environment do
    titles = ENV.fetch('TITLES').split(';').map(&:strip)
    language = ENV.fetch('LANGUAGE', 'en')
    wiki = Wiki.get_or_create(language:, project: 'wikipedia')

    titles.each do |title|
      extractor = ExtractClaimsAndSources.new(wiki, title:)
      examples = extractor.claims.map do |claim|
        claim.merge(article_title: extractor.article_title,
                    mw_page_id: extractor.mw_page_id,
                    mw_rev_id: extractor.mw_rev_id,
                    wiki_domain: wiki.domain)
      end
      added = SourceVerificationExampleStore.add(examples)
      puts "#{title}: extracted #{examples.length}, added #{added}"
    end
    puts "Store now holds #{SourceVerificationExampleStore.count} examples."
  end

  desc 'Harvest claim/source examples from a course\'s student work (COURSE slug)'
  task harvest_course: :environment do
    course = Course.find_by!(slug: ENV.fetch('COURSE'))
    finder = FindSourceVerificationExamples.new(
      course,
      max_examples: ENV.fetch('MAX_EXAMPLES', 25).to_i,
      max_articles: ENV.fetch('MAX_ARTICLES', 10).to_i
    )
    added = SourceVerificationExampleStore.add(finder.examples)
    puts "#{course.slug}: extracted #{finder.examples.length}, added #{added}"
    puts "Store now holds #{SourceVerificationExampleStore.count} examples."
  end
end

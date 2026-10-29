# frozen_string_literal: true

# Builds and uses a claim library: Wikipedia claims, their cited sources, and
# human judgments of how well each source backs its claim. See
# docs/claim_library.md. Library files and the source cache live under data/,
# which git ignores.
namespace :claim_library do
  def claim_library_path
    ENV['LIBRARY'].presence ||
      abort('Set LIBRARY to the library file, eg data/claim_library/surrogacy.jsonl')
  end

  def claim_library_fetcher
    require_dependency "#{Rails.root}/lib/claim_library/source_fetcher"
    cache_dir = ENV['CACHE'].presence || 'data/claim_library/sources'
    contact = ENV['CONTACT'].presence || ENV.fetch('dashboard_url', 'dev')
    ClaimLibrary::SourceFetcher.new(cache_dir:, contact:)
  end

  def claim_library
    require_dependency "#{Rails.root}/lib/claim_library/library"
    ClaimLibrary::Library.new(claim_library_path)
  end

  def write_or_print(markdown)
    ENV['OUT'].present? ? File.write(ENV['OUT'], markdown) : puts(markdown)
  end

  desc 'Add every cited sentence of a revision to a library. ' \
       'ENV: LIBRARY, REV or TITLE (latest revision), LANGUAGE (default en)'
  task extract: :environment do
    wiki = Wiki.get_or_create(language: ENV['LANGUAGE'].presence || 'en', project: 'wikipedia')
    if ENV['REV'].blank? && ENV['TITLE'].blank?
      abort 'Set REV to a revision id or TITLE to an article title'
    end
    build = BuildClaimLibraryRecords.new(wiki:, mw_rev_id: ENV['REV'].presence&.to_i,
                                         title: ENV['TITLE'].presence)
    library = claim_library
    added = library.add(build.records)
    library.save
    puts "#{build.article_title} (revision #{build.mw_rev_id}): #{build.records.size} cited " \
         "sentences, #{added} new. Library now holds #{library.records.size} claims."
  end

  desc 'Read and cache the source behind every claim in a library. ENV: LIBRARY, CACHE, CONTACT'
  task fetch: :environment do
    library = claim_library
    fetcher = claim_library_fetcher
    library.records.each do |record|
      next puts("#{record.id}: offline source") if record.source_url.nil?
      record.source = fetcher.fetch(record.source_url, archive_url: record.archive_url)
      puts "#{record.id}: #{record.source.status} #{record.source.read_from || record.source.error}"
    end
    library.save
  end

  desc 'Judge the unjudged claims in a library, one at a time. ENV: LIBRARY, ANNOTATOR, CACHE'
  task annotate: :environment do
    require_dependency "#{Rails.root}/lib/claim_library/annotator"
    annotator = ENV['ANNOTATOR'].presence || abort('Set ANNOTATOR to your name')
    recorded = ClaimLibrary::Annotator.new(library: claim_library, fetcher: claim_library_fetcher,
                                           annotator:).run
    puts "Recorded #{recorded} judgment#{'s' unless recorded == 1}."
  end

  desc 'Write the library as a Markdown report. ENV: LIBRARY, OUT (default: print)'
  task report: :environment do
    require_dependency "#{Rails.root}/lib/claim_library/report"
    write_or_print(ClaimLibrary::Report.new(claim_library).to_markdown)
  end

  desc 'Compare an automated verifier with the human judgments. ' \
       'ENV: LIBRARY, VERIFIER (a command), OUT'
  task benchmark: :environment do
    require_dependency "#{Rails.root}/lib/claim_library/verifier_comparison"
    command = ENV['VERIFIER'].presence || abort('Set VERIFIER to the command that judges a claim')
    comparison = ClaimLibrary::VerifierComparison.new(library: claim_library, command:,
                                                      fetcher: claim_library_fetcher).run
    write_or_print(comparison.to_markdown)
  end
end

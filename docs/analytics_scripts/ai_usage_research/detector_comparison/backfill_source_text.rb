# frozen_string_literal: true

# One-time backfill of ai_detection_samples.source_text and source_format for units built
# before those columns existed (October 2026). Run in a production Rails console after the
# deploy that added the columns:
#
#   load '/home/sage/backfill_source_text.rb'
#   backfill_sources_from_csv('/home/sage/generated_sources_2026-10.csv')
#   backfill_sources_from_csv('/home/sage/agpedia_sources_2026-10.csv')
#   backfill_wikitext_sources(verbose: true)
#
# The CSVs come from exemplars/source_texts.py. Each row names units by the SHA-256 of their
# plain_text, so it fills every unit with that text, in any sample. Wikipedia units get their
# wikitext fetched again, and only when the plain text fetched alongside it still matches the
# stored text, so the source always belongs to the text the detectors scored.

require 'csv'

def backfill_sources_from_csv(path)
  filled = 0
  CSV.foreach(path, headers: true) do |row|
    filled += AiDetectionSample.where(text_sha256: row['text_sha256'], source_text: nil)
                               .update_all(source_text: row['source_text'],
                                           source_format: row['source_format'],
                                           updated_at: Time.zone.now)
  end
  puts "#{filled} units filled from #{File.basename(path)}"
end

def backfill_wikitext_sources(sample_names: nil, verbose: false)
  units = AiDetectionSample.where(source_text: nil).where.not(rev_id: nil).includes(:wiki)
  units = units.where(sample_name: sample_names) if sample_names
  counts = Hash.new(0)
  units.find_each do |unit|
    counts[backfill_wikitext_source(unit)] += 1
    puts "#{unit.id}: #{counts.inspect}" if verbose
  end
  counts
end

def backfill_wikitext_source(unit)
  plaintext = GetRevisionPlaintext.new(unit.rev_id, unit.wiki, diff_mode: unit.diff_mode,
                                                               from_rev: unit.from_rev_id)
  return :text_changed if Digest::SHA256.hexdigest(plaintext.plain_text.to_s) != unit.text_sha256

  wikitext = plaintext.changed_wikitext.presence ||
             WikiApi::ArticleContent.new(unit.wiki).revision_wikitext(unit.rev_id)
  return :no_wikitext if wikitext.blank?

  unit.update_columns(source_text: wikitext, source_format: AiDetectionSample::WIKITEXT)
  :filled
rescue MediawikiApi::ApiError, Faraday::Error
  :failed
end

# frozen_string_literal: true

require_dependency "#{Rails.root}/lib/utils/wiki_url_parser"

# Base for the strategies that assemble a named AiDetectionSample: a set of
# text units (usually the text added by a revision or diff, sometimes raw text)
# that ScoreAiDetectionSample later sends to one or more AI detectors.
# Subclasses enumerate candidate units and call #add_url_unit,
# #add_revision_unit or #add_text_unit; this class fetches the plaintext once,
# skips units without enough prose, and never adds the same unit to a sample
# twice. Nothing here calls a detector.
#
# Unit attributes every strategy may set: ground_truth (AiDetectionSample::HUMAN,
# AI, AI_ASSISTED or nil), provenance (how we know), notes, factors (named
# values that link units, e.g. 'topic', 'author', 'model', 'prompt'),
# campaign_slug, and free-form metadata.
class BuildAiDetectionSample
  attr_reader :sample_name, :created, :existing, :skipped

  # Same floor as production alerting; shorter text is not worth a detector call.
  MIN_PLAIN_TEXT_LENGTH = CheckRevisionWithPangram::MIN_PLAIN_TEXT_LENGTH

  # rev_id, from_rev_id and revision_ai_scores.revision_id are 4-byte integer
  # columns. Wikipedia revision ids are far below the limit (Wikidata's passed
  # it in 2024); a stray larger id is skipped rather than crashing the build.
  MAX_REVISION_ID = (2**31) - 1

  # Terms that ended before ChatGPT's release on 2022-11-30 are a human-written
  # baseline. Fall 2022 courses overlapped the release, so they are not.
  def self.term_attributes(slug)
    match = slug.to_s.match(/\A(?<season>spring|summer|fall)_(?<year>\d{4})\z/)
    return {} unless match

    year = match['year'].to_i
    pre_llm = year < 2022 || (year == 2022 && match['season'] != 'fall')
    return {} unless pre_llm

    { ground_truth: AiDetectionSample::HUMAN, provenance: AiDetectionSample::PRE_LLM_TERM }
  end

  def initialize(sample_name:, verbose: false)
    @sample_name = sample_name
    @verbose = verbose
    @created = []
    @existing = []
    @skipped = []
  end

  def summary
    { sample_name:, created: created.count, existing: existing.count, skipped: skipped.count }
  end

  private

  def add_url_unit(url, **attrs)
    parser = WikiUrlParser.new(url.to_s)
    target = parser.revision_target
    return skip(url, 'no revision in url') unless target && parser.wiki

    add_revision_unit(wiki: parser.wiki, url:, **target, **attrs)
  end

  def add_revision_unit(wiki:, rev_id:, from_rev: nil, diff_mode: true, url: nil, **attrs)
    reason = unusable_reason(wiki, rev_id, from_rev)
    return skip(url || rev_id, reason) if reason

    unit = AiDetectionSample.find_by(sample_name:, wiki_id: wiki.id, rev_id:,
                                     from_rev_id: from_rev, diff_mode:)
    return remember(existing, unit) if unit

    text = GetRevisionPlaintext.new(rev_id, wiki, diff_mode:, from_rev:).plain_text
    return skip(url || rev_id, 'not enough text') if text.to_s.length < MIN_PLAIN_TEXT_LENGTH

    create_unit(wiki:, rev_id:, from_rev_id: from_rev, diff_mode:, plain_text: text,
                url: url || unit_url(wiki, rev_id, from_rev, diff_mode), **attrs)
  rescue MediawikiApi::ApiError, Faraday::Error => e
    skip(url || rev_id, "#{e.class}: #{e.message}")
  end

  # AI detection is only meaningful on Wikipedia article prose; Wikidata and the
  # other projects are out of scope for every sampling strategy.
  def unusable_reason(wiki, rev_id, from_rev)
    return "#{wiki.domain} is not a Wikipedia" unless wiki.project == 'wikipedia'

    oversized = [rev_id, from_rev].compact.find { |id| id.to_i > MAX_REVISION_ID }
    "revision id #{oversized} exceeds the 4-byte column" if oversized
  end

  # For text that did not come from a wiki revision: synthetic exemplars, text
  # from other sites, experiment output. The url, if any, is only a reference.
  def add_text_unit(plain_text:, url: nil, **attrs)
    sha = Digest::SHA256.hexdigest(plain_text.to_s)
    unit = AiDetectionSample.find_by(sample_name:, text_sha256: sha)
    return remember(existing, unit) if unit
    return skip(url || sha, 'not enough text') if plain_text.to_s.length < MIN_PLAIN_TEXT_LENGTH

    create_unit(plain_text:, url:, **attrs)
  end

  def create_unit(**attrs)
    unit = AiDetectionSample.create!(sample_name:, **attrs)
    log "added unit #{unit.id} (#{unit.word_count} words): #{unit.url || unit.text_sha256[0, 12]}"
    remember(created, unit)
  end

  def unit_url(wiki, rev_id, from_rev, diff_mode)
    base = "https://#{wiki.domain}/w/index.php?"
    return "#{base}oldid=#{rev_id}" unless diff_mode
    return "#{base}diff=#{rev_id}" if from_rev.nil?

    "#{base}diff=#{rev_id}&oldid=#{from_rev}"
  end

  def remember(list, unit)
    list << unit
    unit
  end

  def skip(reference, reason)
    log "skipped #{reference}: #{reason}"
    skipped << { reference:, reason: }
    nil
  end

  def log(message)
    puts message if @verbose # rubocop:disable Rails/Output
  end
end

# frozen_string_literal: true

require_dependency "#{Rails.root}/lib/metrics_glossary"
require_dependency "#{Rails.root}/lib/metrics_glossary/checker"

namespace :metrics do
  desc 'Check the /metrics glossary (docs/metrics/) against the code'
  task check: :environment do
    errors = MetricsGlossary::Checker.new.errors
    if errors.empty?
      puts 'The metrics glossary is consistent with the code.'
    else
      puts errors.map { |error| "- #{error}" }
      abort "#{errors.size} problem(s) with the metrics glossary."
    end
  end

  desc 'Record that glossary entries still describe the formulas and constants they point at'
  task accept: :environment do
    glossary = MetricsGlossary.new
    fingerprints = MetricsGlossary::Fingerprints.new(glossary)
    owners = fingerprints.owners_by_target
    fingerprints.changed.each do |target|
      puts "Accepting changed #{target} (#{owners[target].join(', ')})"
    end
    fingerprints.unrecorded.each { |target| puts "Recording #{target}" }
    fingerprints.stale.each { |target| puts "Dropping #{target}" }
    fingerprints.write!
  end
end

# frozen_string_literal: true

# Turns articlequality prediction probabilities into a single score
module WeightedScoreCalculator
  # Given a hash of articlequality probabilities and a wiki language, it calculates
  # the weighted mean score. Notice that language is necessary because the raiting
  # and weighting depend on it.
  # The probabilities hash is expected to be something like
  # { "B" => 0.09784360827036567, "C" => 0.22955840375169326, "FA" => 0.003933867294088992,
  #   "GA" => 0.011813817865728837, "Start" => 0.6380422388204124, "Stub" => 0.018808063997710744 }
  def weighted_mean_score(probabilities, language)
    return unless probabilities
    return unless WEIGHTING_BY_LANGUAGE[language]
    mean = 0
    WEIGHTING_BY_LANGUAGE[language].each do |rating, weight|
      mean += probabilities[rating] * weight
    end
    mean
  end

  # LiftWing articlequality ratings are often derived from the en.wiki system,
  # so this is the fallback scheme.
  ENWIKI_WEIGHTING = { 'FA'    => 100,
                       'GA'    => 80,
                       'B'     => 60,
                       'C'     => 40,
                       'Start' => 20,
                       'Stub'  => 0 }.freeze
  FRWIKI_WEIGHTING = { 'adq' => 100,
                       'ba' => 80,
                       'a' => 60,
                       'b' => 40,
                       'bd' => 20,
                       'e' => 0 }.freeze
  TRWIKI_WEIGHTING = { 'sm' => 100,
                       'km' => 80,
                       'b' => 60,
                       'c' => 40,
                       'baslagıç' => 20,
                       'taslak' => 0 }.freeze
  RUWIKI_WEIGHTING = { 'ИС' => 100,
                       'ДС' => 80,
                       'ХС' => 80,
                       'I' => 60,
                       'II' => 40,
                       'III' => 20,
                       'IV' => 0 }.freeze
  PTWIKI_WEIGHTING = { '6' => 100,
                       '5' => 80,
                       '4' => 60,
                       '3' => 40,
                       '2' => 20,
                       '1' => 0 }.freeze
  UKWIKI_WEIGHTING = { 'ДС' => 100,
                       'ВС' => 80,
                       'I' => 60,
                       'II' => 40,
                       'III' => 20,
                       'IV' => 0 }.freeze
  # SV wiki has three high ratings, all of which are rare:
  # This is just a guess at appropriate weighting for the case where almost
  # all articles are the lowest tier.
  SVWIKI_WEIGHTING = { 'u' => 100,
                       'b' => 90,
                       'r' => 80,
                       's' => 0 }.freeze
  NLWIKI_WEIGHTING = { 'A' => 100,
                       'B' => 75,
                       'C' => 50,
                       'D' => 25,
                       'E' => 0 }.freeze
  WEIGHTING_BY_LANGUAGE = {
    'en' => ENWIKI_WEIGHTING,
    'simple' => ENWIKI_WEIGHTING,
    'fa' => ENWIKI_WEIGHTING,
    'eu' => ENWIKI_WEIGHTING,
    'fr' => FRWIKI_WEIGHTING,
    'tr' => TRWIKI_WEIGHTING,
    'ru' => RUWIKI_WEIGHTING,
    'uk' => UKWIKI_WEIGHTING,
    'gl' => ENWIKI_WEIGHTING,
    'sv' => SVWIKI_WEIGHTING,
    'nl' => NLWIKI_WEIGHTING,
    'pt' => PTWIKI_WEIGHTING
  }.freeze
end

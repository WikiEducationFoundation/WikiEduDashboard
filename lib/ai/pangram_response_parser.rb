# frozen_string_literal: true

class PangramResponseParser
  def initialize(version, response)
    @version = version
    @response = response
  end

  def pangram_v3?
    @version == RevisionAiScore::PANGRAM_V3_KEY
  end

  def pangram_v4?
    @version == RevisionAiScore::PANGRAM_V4_KEY
  end

  # This data structure was created based on Pangram v2,
  # and has been adapted to work for Pangram v3 by
  # switching to analogous renamed fields and/or
  # implementing calculations to derive a closely
  # analagous field from v3 results.
  # See https://www.pangram.com/blog/v3-api-migration-guide
  # Pangram v4 keeps the same field names and adds per-window
  # humanizer detection, which is included only when present.
  # See https://www.pangram.com/blog/pangram-4-migration-guide
  def pangram_details
    details = {
      pangram_prediction:,
      headline_result:,
      average_ai_likelihood:,
      max_ai_likelihood:,
      fraction_human_content:,
      fraction_ai_content:,
      fraction_mixed_content:,
      window_likelihoods:,
      predicted_ai_window_count:,
      pangram_share_link:,
      pangram_version:
    }
    return details unless humanizer_data?

    details.merge(humanized_window_count:, max_humanizer_score:)
  end

  def pangram_prediction
    @response['prediction']
  end

  def average_ai_likelihood
    window_likelihoods.sum.fdiv(window_likelihoods.count)
  end

  def max_ai_likelihood
    window_likelihoods.max
  end

  def fraction_human_content
    @response['fraction_human']
  end

  def fraction_ai_content
    @response['fraction_ai']
  end

  def fraction_mixed_content
    @response['fraction_ai_assisted']
  end

  def headline_result
    @response['headline']
  end

  def pangram_version
    @response['version']
  end

  def windows
    @response['windows']
  end

  def window_likelihoods
    windows.map { |window| window['ai_assistance_score'] }
  end

  def predicted_ai_window_count
    window_likelihoods.count { |likelihood| likelihood > 0.5 }
  end

  # Pangram 4 flags windows that look like AI text passed through a "humanizer"
  # tool meant to evade detection. Pangram 3 responses lack these fields.
  def humanizer_data?
    windows.any? { |window| window.key?('is_humanized') }
  end

  def humanized_window_count
    windows.count { |window| window['is_humanized'] }
  end

  def max_humanizer_score
    windows.filter_map { |window| window['humanizer_score'] }.max
  end

  def pangram_share_link
    @response['dashboard_link']
  end

  # Deletes text field from the pangram response to avoid storing that into the db
  def clean_result
    result = @response.dup
    result.delete('text')
    if result['windows'].is_a?(Array)
      result['windows'] = result['windows'].map { |w| w.except('text') }
    end
    result
  end
end

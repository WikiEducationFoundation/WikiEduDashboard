# frozen_string_literal: true

class PangramResponseParser
  def initialize(version, response)
    @version = version
    @response = response
  end

  def pangram_v2?
    @version == RevisionAiScore::PANGRAM_V2_KEY
  end

  def pangram_v3?
    @version == RevisionAiScore::PANGRAM_V3_KEY
  end

  # This data structure was created based on Pangram v2,
  # and has been adapted to work for Pangram v3 by
  # switching to analogous renamed fields and/or
  # implementing calculations to derive a closely
  # analagous field from v3 results.
  # See https://www.pangram.com/blog/v3-api-migration-guide
  def pangram_details
    {
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
  end

  def pangram_prediction
    @response['prediction']
  end

  def average_ai_likelihood
    return @response['avg_ai_likelihood'] if pangram_v2?
    window_likelihoods.sum.fdiv(window_likelihoods.count) if pangram_v3?
  end

  def max_ai_likelihood
    return @response['max_ai_likelihood'] if pangram_v2?
    window_likelihoods.max if pangram_v3?
  end

  def fraction_human_content
    @response['fraction_human']
  end

  def fraction_ai_content
    @response['fraction_ai']
  end

  def fraction_mixed_content
    return @response['fraction_mixed'] if pangram_v2?
    @response['fraction_ai_assisted'] if pangram_v3?
  end

  def headline_result
    @response['headline']
  end

  def pangram_version
    @response['version']
  end

  def window_likelihoods
    return @response['window_likelihoods'] if pangram_v2?
    @response['windows'].map { |window| window['ai_assistance_score'] } if pangram_v3?
  end

  def predicted_ai_window_count
    return @response['window_likelihoods'].count { |likelihood| likelihood > 0.5 } if pangram_v2?
    window_likelihoods.count { |likelihood| likelihood > 0.5 } if pangram_v3?
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
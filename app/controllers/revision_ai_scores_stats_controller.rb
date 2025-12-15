# frozen_string_literal: true
# Controller for showing revision AI scores stats
class RevisionAiScoresStatsController < ApplicationController
  layout 'admin'
  before_action :check_user_auth

  def index
    set_data
  end

  private

  NUMBER_OF_BINS = 10

  def set_data
    set_scores
    set_avg_likelihoods
    set_max_likelihoods
    set_historical_scores_by_namespaces
    set_historical_scores_by_max_values
    set_historical_scores_by_avg_values
  end

  def set_scores
    @scores = RevisionAiScore.all.includes(:article)
    @scores_with_likelihood = @scores.where.not(avg_ai_likelihood: nil)
  end

  def set_avg_likelihoods
    @avg_likelihoods = @scores.map { |s| { value: s.avg_ai_likelihood } }
  end

  def set_max_likelihoods
    @max_likelihoods = @scores.map { |s| { value: s.max_ai_likelihood } }
  end

  # Sets an array of hashes with date, namespace, and count for historical scores.
  # The array covers the full date range and all namespaces, even if the count is zero
  # for some combinations.
  # The array also contains a bin field that always has the value -1, since it’s not
  # really necessary in this case.
  def set_historical_scores_by_namespaces
    count_by_date_and_namespace = @scores.group_by do |s|
      # -1 represents an invalid bin
      [s.revision_datetime.to_date, s.article.namespace, -1]
    end
                                    .transform_values(&:count)

    # Ensure all date and namespace combinations exist, even when count is zero.
    namespaces = count_by_date_and_namespace.keys.map(&:second).uniq
    @historical_scores_by_namespace = complete_hash(namespaces, [-1], count_by_date_and_namespace)
  end

  # Sets an array of hashes with date, namespace, bins based on max likelihood, and count for
  # historical scores. The array covers the full date range and all bins, even if the count is zero
  # for some combinations.
  def set_historical_scores_by_max_values
    count_by_date_ns_and_bin = @scores_with_likelihood.group_by do |s|
      [s.revision_datetime.to_date, s.article.namespace, bin(s.max_ai_likelihood)]
    end
                                    .transform_values(&:count)

    # Ensure all date, namespace and bin combinations exist, even when count is zero.
    namespaces = count_by_date_ns_and_bin.keys.map(&:second).uniq
    @historical_scores_by_max = complete_hash(namespaces, (0..NUMBER_OF_BINS).to_a,
                                              count_by_date_ns_and_bin)
  end

  # Sets an array of hashes with date, namespace, bins based on avg likelihood, and count for
  # historical scores. The array covers the full date range and all bins, even if the count is zero
  # for some combinations.
  def set_historical_scores_by_avg_values
    count_by_date_ns_and_bin = @scores_with_likelihood.group_by do |s|
      [s.revision_datetime.to_date, s.article.namespace, bin(s.avg_ai_likelihood)]
    end
                                    .transform_values(&:count)

    namespaces = count_by_date_ns_and_bin.keys.map(&:second).uniq
    @historical_scores_by_avg = complete_hash(namespaces, (0..NUMBER_OF_BINS).to_a,
                                              count_by_date_ns_and_bin)
  end

  # Given arrays of possible namespaces and bins, and a partial array of hashes, returns a complete
  # array of hashes that includes all dates, namespaces and bins based on the partial one.
  def complete_hash(namespaces, bins, partial_stats)
    start_date = partial_stats.keys.map(&:first).min
    end_date   = partial_stats.keys.map(&:first).max

    (start_date..end_date).flat_map do |created_at|
      bins.flat_map do |bin|
        namespaces.map do |namespace|
          { created_at: created_at.to_s,
            namespace:,
            bin:,
            count: partial_stats.fetch([created_at, namespace, bin], 0) }
        end
      end
    end
  end

  # Given a value between 0 and 1, determines to which bin belongs
  def bin(value)
    # We want to keep 1.0 in the last bin
    return NUMBER_OF_BINS - 1 if value == 1
    (value * NUMBER_OF_BINS).floor
  end

  def check_user_auth
    return if current_user&.admin?
    flash[:notice] = "You don't have access to that page."
    redirect_to root_path
  end
end

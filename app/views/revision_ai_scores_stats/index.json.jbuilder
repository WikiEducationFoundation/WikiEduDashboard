# frozen_string_literal: true

json.total_scores @scores.count
json.avg_likelihoods @avg_likelihoods
json.max_likelihoods @max_likelihoods
json.count_by_namespace @count_by_namespace
json.count_by_max @count_by_max
json.count_by_avg @count_by_avg
json.historical_scores_by_namespace @historical_scores_by_namespace
json.historical_scores_by_max @historical_scores_by_max
json.historical_scores_by_avg @historical_scores_by_avg

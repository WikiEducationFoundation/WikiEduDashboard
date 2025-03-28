# frozen_string_literal: true
# This script is to clean article_id for assignments associated to article records
# that are set as deleted
Assignment.joins(:article).where(articles: { deleted: true }).in_batches do |batch|
  batch.update_all(article_id: nil) # rubocop:disable Rails/SkipsModelValidations
end

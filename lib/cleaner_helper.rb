# frozen_string_literal: true

# Shared helper for cleaner classes that bulk-delete records. Deletes from an
# ActiveRecord::Relation in primary-key batches, without loading the ids into
# memory, so each batch is its own statement and InnoDB purge and replication
# can keep up between batches.
module CleanerHelper
  # Number of records deleted per batch when bulk-deleting.
  DELETE_BATCH_SIZE = 5000

  private

  def delete_in_batches(relation)
    relation.in_batches(of: DELETE_BATCH_SIZE).delete_all
  end
end

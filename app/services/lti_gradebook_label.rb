# frozen_string_literal: true

# The Canvas gradebook column label for a timeline block, shared by the service
# that syncs line items (SyncLtiLineItems) and the deep-link picker
# (DeepLinkableGradables) — and thus ResolveAssignmentLineItem — so a milestone
# reads the same everywhere it becomes a column.
#
# The label is "Wk<n> <name>", where <name> is the operator's short label for
# the block's exercise (config/lti_exercise_gradebook_labels.yml) when one is
# defined, otherwise the full timeline block title. Truncated to Canvas's
# 64-character AGS label limit.
module LtiGradebookLabel
  EXERCISE_LABELS = YAML.safe_load_file(
    Rails.root.join('config/lti_exercise_gradebook_labels.yml')
  ).freeze

  module_function

  def for_block(block)
    week_order = block.week&.order
    prefix = week_order ? "Wk#{week_order} " : ''
    "#{prefix}#{exercise_name(block)}".byteslice(0, 64)
  end

  def exercise_name(block)
    slug = block.training_modules.find(&:exercise?)&.slug
    EXERCISE_LABELS[slug] || block.title
  end
end

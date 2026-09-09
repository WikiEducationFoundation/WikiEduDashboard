# frozen_string_literal: true

# One-off console script. Where a course already has the Fact verification
# exercise block and the Evaluate Wikipedia block in the SAME week, move the
# Fact verification block to sit immediately after the Evaluate Wikipedia block.
#
#   move_fact_verification_blocks                    # dry run, reports only
#   move_fact_verification_blocks(dry_run: false)    # actually writes

def move_fact_verification_blocks(dry_run: true, only_unended: true)
  fv_module = 86           # Exercise: Fact verification
  eval_modules = [34, 57]  # Exercise: Evaluate Wikipedia (+ the professional variant)
  mods = ->(block) { block.training_module_ids.map(&:to_i) }
  report = Hash.new { |h, k| h[k] = [] }

  # training_module_ids is a serialized YAML array, so prefilter on the stored
  # text in SQL and confirm in Ruby.
  candidates = Block.where('training_module_ids LIKE ?', "%- #{fv_module}\n%")
                    .select { |b| mods.call(b).include?(fv_module) }

  candidates.each do |fv|
    course = fv.course
    next report[:no_course] << "block #{fv.id}" if course.nil?
    if only_unended && course.end.present? && course.end < Time.zone.now
      next report[:course_ended] << course.slug
    end

    # A block carrying the FV exercise alongside other modules is somebody's
    # hand-merged block; moving it would drag unrelated content along with it,
    # so report and leave it alone.
    unless mods.call(fv) == [fv_module]
      key = (mods.call(fv) & eval_modules).any? ? :merged_with_eval : :merged_with_other
      next report[key] << "#{course.slug} — block #{fv.id} #{fv.title.inspect} #{mods.call(fv)}"
    end

    week = fv.week
    # `order` is not unique within a week in real data, so break ties by id to
    # read the current sequence deterministically.
    blocks = week.blocks.to_a.sort_by { |b| [b.order.to_i, b.id] }
    # First Evaluate block wins, in case a week somehow has more than one.
    eval_block = blocks.find { |b| (mods.call(b) & eval_modules).any? }
    next report[:not_same_week] << course.slug if eval_block.nil?
    next report[:already_after] << course.slug if blocks.index(fv) > blocks.index(eval_block)

    reordered = blocks - [fv]
    reordered.insert(reordered.index(eval_block) + 1, fv)

    report[:moved] << "#{course.slug} (week #{week.order}): " +
                      reordered.map { |b| b == fv ? "[#{b.title}]" : b.title.to_s }.join(' -> ')

    next if dry_run

    # Renumber the week contiguously, the same way the timeline editor does
    # after a drag. update_column because `order` has no validations, nothing
    # derives a date from it (BlockDateManager keys off week.order), and it
    # skips the LTI line-item sync callback, which a pure reorder doesn't affect.
    reordered.each_with_index do |b, i|
      b.update_column(:order, i) unless b.order == i
    end
  end

  puts dry_run ? "\n=== DRY RUN — nothing written ===" : "\n=== WROTE CHANGES ==="
  report.each do |key, entries|
    puts "\n#{key} (#{entries.size})"
    entries.each { |e| puts "  #{e}" }
  end
  nil
end

# frozen_string_literal: true

# Cuts a text at the boundaries of Pangram's windows, so a page can shade each
# window where it falls. Pangram reports each window's character offsets in
# the text it was sent. When the last window ends at the text's end, the
# offsets map straight onto the text. Otherwise Pangram measured a slightly
# different text (it may normalize whitespace), so the offsets are scaled to
# the text's length, moved to the nearest space, and marked approximate.
class PangramWindowSegments
  SNAP_DISTANCE = 30

  attr_reader :parts

  def initialize(text, windows)
    @text = text
    @windows = windows.select { |window| window['start_index'] && window['end_index'] }
    @parts = []
    cut if @windows.any? && @text.present?
  end

  def approximate?
    @parts.any? && approximate_mapping?
  end

  private

  def last_end
    @windows.map { |window| window['end_index'] }.max
  end

  def cut
    position = 0
    ordered = @windows.each_with_index.sort_by { |window, _index| window['start_index'] }
    ordered.each do |window, index|
      start = [offset(window['start_index']), position].max
      finish = offset(window['end_index'])
      add_part(position, start, nil)
      add_part(start, finish, index)
      position = [position, finish].max
    end
    add_part(position, @text.length, nil)
  end

  def add_part(start, finish, window)
    @parts << { text: @text[start...finish], window: } if finish > start
  end

  def offset(index)
    return [index, @text.length].min unless approximate_mapping?
    return @text.length if index >= last_end

    snap((index * @text.length.fdiv(last_end)).round)
  end

  def approximate_mapping?
    @approximate_mapping = last_end != @text.length if @approximate_mapping.nil?
    @approximate_mapping
  end

  def snap(index)
    return index if index.zero? || @text[index - 1]&.match?(/\s/)

    before = @text.rindex(/\s/, index)
    after = @text.index(/\s/, index)
    nearest = [before && before + 1, after && after + 1].compact.min_by { |i| (i - index).abs }
    nearest && (nearest - index).abs <= SNAP_DISTANCE ? nearest : index
  end
end

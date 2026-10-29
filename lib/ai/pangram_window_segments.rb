# frozen_string_literal: true

# Cuts a text at the boundaries of Pangram's windows, so a page can shade each
# window where it falls. Pangram reports each window's character offsets in
# the text it was sent; for multi-window texts they fall at sentence ends and
# map straight onto the stored text. A text Pangram scored as one window often
# reports an end a little short of the text's end (checked on 1,914 Pangram 4
# results, October 2026), so a lone window covers the whole text. Offsets past
# the text's end would mean Pangram measured a different text: they are scaled
# to the text's length, moved to the nearest space, and marked approximate.
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
    return lone_window_offset(index) if @windows.one?
    return [index, @text.length].min unless approximate_mapping?
    return @text.length if index >= last_end

    snap((index * @text.length.fdiv(last_end)).round)
  end

  def approximate_mapping?
    @approximate_mapping = last_end > @text.length if @approximate_mapping.nil?
    @approximate_mapping
  end

  def lone_window_offset(index)
    index.zero? ? 0 : @text.length
  end

  def snap(index)
    return index if index.zero? || @text[index - 1]&.match?(/\s/)

    before = @text.rindex(/\s/, index)
    after = @text.index(/\s/, index)
    nearest = [before && before + 1, after && after + 1].compact.min_by { |i| (i - index).abs }
    nearest && (nearest - index).abs <= SNAP_DISTANCE ? nearest : index
  end
end

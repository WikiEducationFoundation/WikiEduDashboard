# frozen_string_literal: true

class StringUtils
  class << self
    # @param text The text to be looked at
    # @param kword The token to be searched
    # @param length The desired length of the excerpt
    def excerpt(text, kword, length)
      return '' if text.nil?

      txt = text.tr "\n", ''
      pos = txt.downcase.index(/#{kword}/i)

      # ie "My text..." if no kword found
      return "#{txt[0..length - 4]}..." if pos.nil?

      # length of segment before + after kword
      padding = (length / 2) - 3
      # ... + txt[pos - 30 .. pos + 30] + ...
      excerpted = "...#{txt[([pos - padding, 0].max)..(pos + padding - 1)]}..."
      highlight_kword(excerpted, kword)
    end

    def highlight_kword(text, kword)
      return nil if text.nil?
      return text if kword.nil? || kword.empty?

      text.sub(/#{kword}/i) { |m| "<mark>#{m}</mark>" }
    end
  end
end

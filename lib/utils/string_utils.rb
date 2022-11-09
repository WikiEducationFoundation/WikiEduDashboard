# frozen_string_literal: true

class StringUtils
  class << self
    def excerpt(text, kword, length)
      txt = text.tr "\n", ''
      idx = txt.downcase.index(/#{kword}/i)
      pad = (length / 2) - 3
      tmp = "...#{txt[[idx - pad, 0].max..idx + pad - 1]}..."
      tmp.sub(/#{kword}/i) { |m| "<mark>#{m}</mark>" }
    end
  end
end

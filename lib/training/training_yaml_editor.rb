# frozen_string_literal: true

# Changes top-level values in the text of a training content yml file while
# leaving every other key, comment, and line of formatting exactly as it was,
# so that the resulting diff shows only what actually changed.
#
# The rewritten document is parsed back and compared against the intended
# values; if splicing produced anything else, the whole document is re-dumped
# instead, which is noisier but always correct.
class TrainingYamlEditor
  KEY_LINE = /\A([A-Za-z_][\w-]*):(?=\s|\z)/
  TRAILER_LINE = /\A(#.*)?\s*\z/

  attr_reader :data

  def initialize(text)
    @data = YAML.safe_load(text.to_s, permitted_classes: [Symbol]) || {}
    @expected = @data.dup
    @segments = split(text.to_s)
  end

  # Replaces the value for key, emitting it as `text` if given.
  def set(key, value, text: nil)
    @expected[key] = value
    replacement = text || self.class.emit(key, value)
    segment = segment_for(key)
    if segment
      segment[:replacement] = replacement
    else
      @segments << { key:, lines: [], replacement: }
    end
  end

  # The original text of a key and its value.
  def original_text(key)
    segment_for(key)&.fetch(:lines)&.join
  end

  def to_s
    text = @segments.map { |segment| render(segment) }.join
    self.class.round_trips?(text, @expected) ? text : self.class.dump(@expected)
  end

  # Multi-line strings become literal blocks, which is how slide content is
  # written by hand. Psych would double-quote any string with trailing spaces
  # (markdown line breaks) or tabs.
  def self.emit(key, value)
    block = literal_block(key, value) if value.is_a?(String) && value.include?("\n")
    return block if block && round_trips?(block, { key => value })
    dump({ key => value })
  end

  def self.literal_block(key, value)
    body = value.end_with?("\n") ? value.chomp : value
    first_line = body.lines.find { |line| line.strip.present? }
    indentation = first_line&.start_with?(' ') ? '2' : ''
    lines = body.split("\n", -1).map { |line| line.empty? ? "\n" : "  #{line}\n" }
    "#{key}: |#{indentation}#{chomping_indicator(value)}\n#{lines.join}"
  end

  def self.chomping_indicator(value)
    return '-' unless value.end_with?("\n")
    value.end_with?("\n\n") ? '+' : ''
  end

  def self.round_trips?(text, hash)
    YAML.safe_load(text, permitted_classes: [Symbol]) == hash
  rescue Psych::Exception
    false
  end

  def self.dump(hash)
    hash.to_yaml(line_width: -1).delete_prefix("---\n")
  end

  private

  # Each top-level key starts a segment that runs until the next one. Anything
  # before the first key (a `---` marker, comments) is kept as is.
  def split(text)
    text.each_line.each_with_object([]) do |line, segments|
      key = line[KEY_LINE, 1]
      if key || segments.empty?
        segments << { key:, lines: [line] }
      else
        segments.last[:lines] << line
      end
    end
  end

  def segment_for(key)
    @segments.find { |segment| segment[:key] == key }
  end

  # Comments and blank lines after a value are kept, since they usually
  # introduce whatever comes next.
  def render(segment)
    return segment[:lines].join unless segment[:replacement]
    trailer = segment[:lines].drop(1).reverse.take_while { |line| line.match?(TRAILER_LINE) }
    segment[:replacement] + trailer.reverse.join
  end
end

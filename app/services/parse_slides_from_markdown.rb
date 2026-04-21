# frozen_string_literal: true

# Parses a markdown blob containing one or more slides separated by H2 headings
# into an array of slide hashes suitable for a TrainingModuleDraft.
#
# Example input:
#
#   ## Introduction
#   Welcome to the module.
#
#   ## Why it matters
#   Here is why it matters...
#
# Output:
#
#   [
#     { 'slug' => 'introduction', 'title' => 'Introduction',
#       'content' => "Welcome to the module.\n" },
#     ...
#   ]
class ParseSlidesFromMarkdown
  HEADING_PATTERN = /\A(\#{1,2})[ \t]+(.+?)\s*\z/
  CODE_FENCE_PATTERN = /\A```/

  attr_reader :slides, :heading_level

  def initialize(markdown)
    @markdown = normalize_setext_headings(markdown.to_s)
    @slides = []
    @heading_level = nil
    parse
  end

  private

  def parse
    @current = nil
    @in_code_fence = false
    lines.each { |line| process_line(line) }
    @slides << @current if @current
    raise InvalidFormat, 'Input is empty or contains no slides.' if @slides.empty?
    finalize_slides
  end

  # Convert setext-style headings into ATX form so the rest of the parser can
  # stay simple. Google Docs' "copy as markdown" mode emits setext headings
  # (title on one line, underline of '=' for H1 or '-' for H2 on the next).
  def normalize_setext_headings(text)
    text = text.gsub(/^([^\n=\-][^\n]*?)[ \t]*\n=+[ \t]*$/, '# \1')
    text.gsub(/^([^\n=\-][^\n]*?)[ \t]*\n-{2,}[ \t]*$/, '## \1')
  end

  def process_line(line)
    @in_code_fence = !@in_code_fence if line.match?(CODE_FENCE_PATTERN)
    if !@in_code_fence && (match = slide_heading_match(line))
      @slides << @current if @current
      @current = build_slide(match[2])
      return
    end
    raise_missing_heading if @current.nil? && !line.strip.empty?
    @current['content_lines'] << line if @current
  end

  # Treat the first # or ## heading encountered as the slide-boundary level.
  # Subsequent headings at other levels are kept as content.
  def slide_heading_match(line)
    match = line.match(HEADING_PATTERN)
    return nil unless match
    level = match[1].length
    @heading_level ||= level
    level == @heading_level ? match : nil
  end

  def lines
    @markdown.split("\n", -1)
  end

  def build_slide(title)
    title = title.strip
    { 'title' => title, 'slug' => title.parameterize, 'content_lines' => [] }
  end

  def finalize_slides
    @slides = @slides.map do |slide|
      content = slide['content_lines'].join("\n")
      content = content.sub(/\A\s*\n/, '').sub(/\s*\z/, '')
      content += "\n" unless content.empty?
      { 'title' => slide['title'], 'slug' => slide['slug'], 'content' => content }
    end
  end

  def raise_missing_heading
    raise InvalidFormat,
          'Invalid paste format: expected first non-empty line to start with # or ##.'
  end

  class InvalidFormat < ArgumentError; end
end

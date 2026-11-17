# frozen_string_literal: true

# Removes lines of extracted plain text that are not the editor's own prose, before
# the text goes to an AI detector:
# - bibliography entries and bare URLs, which detectors score unpredictably and
#   which can drag the prose around them into AI-flagged windows;
# - instruction lines from Wiki Education's exercise preload templates that the
#   student left in place;
# - lines that are only a talk-page signature.
# Each rule matches whole lines and errs toward keeping prose. The survey behind
# these rules is in docs/analytics_scripts/pangram_preprocessing_survey.
class NonProseLineFilter
  attr_reader :text

  def initialize(text)
    @text = text.split("\n").reject { |line| non_prose?(line.strip) }.join("\n")
  end

  # Instruction lines of the Dashboard.wikiedu.org preload templates (choose article,
  # evaluate article, bibliography, outline, peer review, sandbox assignment) as
  # GetRevisionPlaintext extracts them. Compared case- and space-insensitively.
  PRELOAD_TEMPLATE_LINES = [
    # Choose an article
    'Article Selection',
    "Please list articles that you're considering for your Wikipedia assignment below. " \
    'Begin to critique these articles and find relevant sources.',
    'Option 1', 'Option 2', 'Option 3', 'Option 4', 'Option 5',
    'Article title', 'Article Evaluation',
    # Evaluate an article
    'Which article are you evaluating?',
    '(Provide a link to the article here.)',
    'Why you have chosen this article to evaluate?',
    '(Briefly explain why you chose it, why it matters, and what your preliminary ' \
    'impression of it was.)',
    'Evaluate the article',
    '(Compose a detailed evaluation of the article here, considering each of the key ' \
    'aspects listed above. Consider the guiding questions, and check out the examples ' \
    'of what a useful Wikipedia article evaluation looks like.)',
    # Bibliography and outline
    'You will be compiling your bibliography in this sandbox.',
    'You will be compiling your bibliography and creating an outline of the changes you ' \
    'will make in this sandbox.',
    'Outline of proposed changes',
    'Click on the edit button to draft your outline.',
    # Peer review
    'General info', 'Whose work are you reviewing?', '(provide username)',
    "Link to draft you're reviewing",
    'Link to the current version of the article (if it exists)',
    'Evaluate the drafted changes',
    'Tone and Balance', 'Sources and References', 'Images and Media',
    'For New Articles Only', 'Overall impressions',
    # Sandbox
    'Article Draft', 'Article body', 'Drafting your article',
    'This is where you will draft your Wikipedia contribution. Please refer to the ' \
    'following resources for help:',
    'Drafting in the sandbox', 'Moving work out of the sandbox',
    'This template should only be used in the user namespace.',
    # Course assignment banner on talk pages
    'This article is or was the subject of a Wiki Education Foundation–supported ' \
    'course assignment.'
  ].to_set { |line| line.squish.downcase }.freeze

  # The peer review instructions run long; students often keep only their start.
  PRELOAD_TEMPLATE_PREFIXES = [
    '(compose a detailed peer review here, considering each of the key aspects',
    'edit this section to compile the bibliography for your wikipedia assignment.'
  ].freeze

  URL = %r{https?://\S+|doi\.org/|\bdoi:|\bISBN\b}i
  BARE_URL = %r{\A(?:https?://|doi:|www\.)\S+\z}i
  # "Surname, Initials" / "Surname, Given." / "Surname, Given; Other" at the start of a
  # line. A comma after a capitalized word alone is not enough: "However, Smith (2019)"
  # is prose.
  SURNAME = /\p{Lu}[\p{L}'’.-]+(?: \p{Lu}[\p{L}'’.-]+)?/
  GIVEN_NAMES = /(?:\p{Lu}\.\s?)+|\p{Lu}[\p{L}'’-]+(?: \p{Lu}\.?)*[.,;]/
  AUTHOR_START = /\A#{SURNAME}, (?:#{GIVEN_NAMES})/
  # "A. Bansal, M. Vo, ..." / "J. Smith and ..."
  INITIALS_START = /\A(?:\p{Lu}\. ?)+\p{Lu}[\p{L}'’-]+(?:,| and | &)/
  # Citation-template output without authors: "Title". Work. Date. Retrieved ...
  QUOTED_TITLE_START = /\A["“][^"”]{3,}(?:[.,]["”]|["”]\s*[.,(])/
  # Publication details that prose rarely carries: a year in parentheses, a
  # publisher, a volume(issue), page or retrieval note.
  PUBLICATION_DETAILS = Regexp.union(
    /\((?:19|20)\d{2}[a-z]?[),]/,
    /University Press|Press,|Publishing|Publishers|Routledge|Springer|Elsevier|Wiley/,
    /Retrieved|Accessed|Journal of|\bpp?\. ?\d|\bvol\. ?\d|\d+\s?\(\d+\)/i
  )
  QUOTED_TITLE = /["“][^"”]{3,}[.,]?["”]/

  SIGNATURE = /\(talk\)\s*\d{1,2}:\d{2}, \d{1,2} \p{L}+ \d{4} \(UTC\)\z/
  # A username is a few words at most; more than that before the signature is a comment.
  MAX_SIGNATURE_NAME_WORDS = 3

  private

  def non_prose?(line)
    return false if line.empty?
    citation?(line) || preload_template_line?(line) || bare_signature?(line)
  end

  # A reference starts with its authors, or with its quoted title when it has none,
  # and carries publication details or a link. A quoted title counts as a detail
  # only after an author, so prose that opens with a quotation stays.
  def citation?(line)
    return true if line.match?(BARE_URL)
    details = line.match?(PUBLICATION_DETAILS) || line.match?(URL)
    if AUTHOR_START.match?(line) || INITIALS_START.match?(line)
      details || line.match?(QUOTED_TITLE)
    else
      QUOTED_TITLE_START.match?(line) && details
    end
  end

  def preload_template_line?(line)
    normalized = line.squish.downcase
    PRELOAD_TEMPLATE_LINES.include?(normalized) ||
      PRELOAD_TEMPLATE_PREFIXES.any? { |prefix| normalized.start_with?(prefix) }
  end

  def bare_signature?(line)
    signature = SIGNATURE.match(line)
    signature && line[0...signature.begin(0)].split.size <= MAX_SIGNATURE_NAME_WORDS
  end
end

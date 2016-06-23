class RevisionFeedbackService
  def initialize(revision)
    @revision = revision
  end

  def feedback
    @feedback = []
    return @feedback if @revision.features.blank?
    citation_feedback
    structure_feedback
    wikilinks_feedback
    default_feedback
    @feedback
  end

  MINIMUM_REFERENCES = 1
  def citation_feedback
    ref_tags = @revision.features['feature.wikitext.revision.ref_tags']
    cite_templates = @revision.features['feature.enwiki.revision.cite_templates']
    if ref_tags < MINIMUM_REFERENCES
      @feedback << 'Cite your sources! This article needs more references.'
    end
  end

  # The largest reasonable average section size, calculated from content characters
  MAXIMUM_AVERAGE_SECTION_SIZE = 8000
  def structure_feedback
    content_characters = @revision.features['feature.wikitext.revision.content_chars']
    h2_headers = @revision.features['feature.wikitext.revision.headings_by_level(2)']
    h3_headers = @revision.features['feature.wikitext.revision.headings_by_level(3)']

    # Articles have a lead section even without a section header
    average_section_size = content_characters / (h2_headers + h3_headers + 1)
    return unless average_section_size > MAXIMUM_AVERAGE_SECTION_SIZE
    @feedback << 'Try improving the structure and organization of this article. Use headers and sub-headers to divide the article into distinct sub-topics.'
  end

  MINIMUM_WIKILINKS = 3
  def wikilinks_feedback
  end

  def default_feedback
    return unless @feedback.blank?
    @feedback << '[no suggestions available]'
  end
end

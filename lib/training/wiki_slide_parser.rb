# frozen_string_literal: true

require "#{Rails.root}/lib/wikitext"

#= Takes wikitext for an on-wiki slide and extracts title and content
class WikiSlideParser
  def initialize(wikitext)
    @wikitext = wikitext&.dup || +''
    set_utf8_encoding
    remove_noinclude
    remove_translation_markers
    remove_translate_tags
    extract_quiz_template
    convert_image_templates
    convert_video_templates
    convert_button_templates
  end

  # The first translated line is the slide title
  def title
    return '' if @wikitext.blank?
    title = @wikitext.lines.first.chomp
    # remove header markup for level 2 or lower
    title.gsub(/==+/, '').strip
  end

  # Everything after the first translated line is the slide content
  def content
    return '' if @wikitext.blank?
    wikitext = @wikitext.lines[1..-1].join # Line 0 is the title
    wikitext[0] = '' while wikitext[0] == "\n" # Remove leading newlines
    markdown = Wikitext.mediawiki_to_markdown(wikitext)
    # Make sure first line after a figure gets parsed as a new paragraph
    markdown.gsub("figure>\n", "figure>\n\n")
  end

  def quiz
    return unless @quiz_template
    { correct_answer_id: quiz_correct_answer,
      question: quiz_question,
      answers: quiz_answers }
  end

  private

  def set_utf8_encoding
    @wikitext = @wikitext.force_encoding('UTF-8')
  end

  def remove_noinclude
    @wikitext.gsub!(%r{<noinclude>.*?</noinclude>\n*}m, '')
  end

  def remove_translation_markers
    # Remove both marker and any trailing whitespace after it,
    # which may interfere with correct markdown conversion.
    # Matches any amount of horizontal whitespace (\h) but at most
    # one newline, to prevent concatenating the title with the contents.
    @wikitext.gsub!(/<!--.+?-->\h*\n??/, '')
  end

  def remove_translate_tags
    # Remove both the tags and any excess whitespace within them,
    # which may interfere with correct markdown conversion.
    @wikitext.gsub!(/<translate>\s*/, '')
    @wikitext.gsub!(%r{\s*</translate>}, '')
    @wikitext.gsub!(/<tvar.*?>/, '')
    @wikitext.gsub!(%r{</>}, '')
  end

  def extract_quiz_template
    @wikitext.gsub!(/(?<template>{{Training module quiz.*?\n}})/m, '')
    @quiz_template = Regexp.last_match && Regexp.last_match['template']
  end

  def quiz_correct_answer
    # Looks like:
    # | correct_answer_id = 3
    Integer(template_parameter_value(@quiz_template, 'correct_answer_id'))
  end

  def quiz_question
    # Looks like:
    # | question = What... is your favorite colour?
    template_parameter_value(@quiz_template, 'question')
  end

  def quiz_answers
    answers = (1..9).map do |answer_number|
      answer_hash(answer_number)
    end
    answers.compact
  end

  def answer_hash(number)
    text = template_parameter_value(@quiz_template, "answer_#{number}")
    return unless text
    explanation = template_parameter_value(@quiz_template, "explanation_#{number}")
    { id: number,
      text: text,
      explanation: explanation }
  end

  def template_parameter_value(template, parameter)
    # Extract value from something like:
    # | parameter_name = value
    match = template.match(/\|\s*#{parameter}\s*=\s*(?<value>.*)/)
    match && match['value']
  end

  def convert_image_templates
    # Get all the image templates on the page to allow for multiple images in the same slide
    image_templates = @wikitext.scan(/(?<image>{{Training module image.*?\n}})/im)
    return unless image_templates
    # Replace each one with the correct figure markup
    image_templates.each do |template|
      @wikitext.sub! template[0], figure_markup_from_template(template[0])
    end
  end

  def convert_video_templates
    # Get all the video templates on the page to allow for multiple videos in the same slide
    video_templates = @wikitext.scan(/(?<video>{{Training module video.*?\n}})/im)
    return unless video_templates
    # Replace each one with the correct video markup
    video_templates.each do |template|
      @wikitext.sub! template[0], video_markup_from_template(template[0])
    end
  end

  def convert_button_templates
    # Get all the button templates on the page to allow for multiple buttons in the same slide
    button_templates = @wikitext.scan(/(?<button>{{Training module button.*?\n}})/im)
    return unless button_templates
    # Replace each one with the correct button markup
    button_templates.each do |template|
      @wikitext.sub! template[0], button_markup_from_template(template[0])
    end
  end

  def figure_markup_from_template(template)
    image_layout = image_layout_from(template)
    image_source = image_source_from(template)
    image_filename = image_filename_from(template)
    image_caption = image_caption_from(template)
    image_credit = image_credit_from(template)
    <<-FIGURE
<figure class="#{image_layout}"><img src="#{image_source}" />
<figcaption class="#{'image-credit' if image_credit}">#{image_caption}
<a href="https://commons.wikimedia.org/wiki/#{image_filename}">#{image_credit}</a>
</figcaption>
</figure>
    FIGURE
  end

  def video_markup_from_template(template)
    video_source = video_source_from(template)
    <<-VIDEO
<iframe width="420" height="315" src="#{video_source}" frameborder="0" allowfullscreen></iframe>
    VIDEO
  end

  def button_markup_from_template(template)
    button_text = template_parameter_value(template, 'text')
    button_link = template_parameter_value(template, 'link')
    <<-BUTTON
<div class="training__button-container"><a target="_blank" class="btn btn-primary" href="#{button_link}">
#{button_text}
</a></div>
    BUTTON
  end

  def image_layout_from(template)
    template_parameter_value(template, 'layout')
  end

  def image_source_from(template)
    template_parameter_value(template, 'source')
  end

  def image_filename_from(template)
    template_parameter_value(template, 'image')
  end

  def image_caption_from(template)
    template_parameter_value(template, 'caption')
  end

  def image_credit_from(template)
    template_parameter_value(template, 'credit')
  end

  def video_source_from(template)
    template_parameter_value(template, 'source')
  end
end

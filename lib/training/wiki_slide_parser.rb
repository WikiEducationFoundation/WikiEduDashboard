# frozen_string_literal: true

#= Takes wikitext for an on-wiki slide and extracts title and content
class WikiSlideParser
  def initialize(wikitext)
    @wikitext = wikitext
    set_utf8_encoding
    remove_noinclude
    remove_translation_markers
    remove_translate_tags
    extract_quiz_template
  end

  # The first translated line is the slide title
  def title
    title = @wikitext.lines.first.chomp
    # remove header markup for level 2 or lower
    title.gsub(/==+/, '').strip
  end

  # Everything after the first translated line is the slide content
  def content
    wikitext = @wikitext.lines[1..-1].join
    wikitext.gsub!(/^\n*/) # Remove leading newlines
    Wikitext.mediawiki_to_markdown(wikitext)
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
    @wikitext.gsub!(/<!--.+?-->\s*\n*/, '')
  end

  def remove_translate_tags
    # Remove both the tags and any excess whitespace within them,
    # which may interfere with correct markdown conversion.
    @wikitext.gsub!(/<translate>\s*/, '')
    @wikitext.gsub!(%r{\s*</translate>}, '')
  end

  def extract_quiz_template
    @wikitext.gsub!(/(?<template>{{Training module quiz.*\n}})/m, '')
    @quiz_template = Regexp.last_match && Regexp.last_match['template']
  end

  def quiz_correct_answer
    # Looks like:
    # | correct_answer_id = 3
    Integer(quiz_parameter_value('correct_answer_id'))
  end

  def quiz_question
    # Looks like:
    # | question = What... is your favorite colour?
    quiz_parameter_value('question')
  end

  def quiz_answers
    answers = (1..9).map do |answer_number|
      answer_hash(answer_number)
    end
    answers.compact
  end

  def answer_hash(number)
    text = quiz_parameter_value("answer_#{number}")
    return unless text
    explanation = quiz_parameter_value("explanation_#{number}")
    { id: number,
      text: text,
      explanation: explanation }
  end

  def quiz_parameter_value(parameter)
    # Extract value from something like:
    # | parameter_name = value
    match = @quiz_template.match(/\|\s*#{parameter}\s*=\s*(?<value>.*)/)
    match && match['value']
  end
end

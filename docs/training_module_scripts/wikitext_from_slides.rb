require_relative "../../lib/wikitext.rb"

library = TrainingLibrary.find_by_slug('wikidata-professional')
modules = library.categories.first['modules'].map { |m| TrainingModule.find_by_slug(m['slug']) }
module_id_suffix = 23

# Takes markdown for a slide and converts it to wikitext
# using the same templates on Meta that WikiSlideParser converts *to* markdown.
class SlideConverter
  def initialize(slide)
    @slide = slide
    @content = Wikitext.markdown_to_mediawiki(slide.content) || ''
    convert_figure_tag
    add_quiz
  end

  def to_wikitext
    @content
  end

  private

  def convert_figure_tag
    figures = @content.scan /(<figure .*<\/figure>)/m
    figures.flatten.each do |figure|
      @content.sub!(figure, image_template(figure))
    end
  end

  def image_template(figure)
    figure_class = figure.scan(/class="(.*?)"/).first.first
    image_source = figure.scan(/src="(.*?)"/).first.first
    filename = "File:#{File.basename(image_source)}"
    caption = figure.scan(/figcaption class="(.*?)">(.*)<\/figcaption>/m).first&.second&.strip

    <<-IMAGE_TEMPLATE
</translate>
<translate>
{{Training module image
  | image =  #{filename}
  | source = #{image_source}
  | layout = #{figure_class}
  | caption =#{Wikitext.markdown_to_mediawiki(caption)}
}}
</translate>
<translate>
    IMAGE_TEMPLATE
  end

  def add_quiz
    return if @slide.assessment.empty?
    @content += quiz_template(@slide.assessment)
  end

  def quiz_template(assessment)
    <<-QUIZ
</translate>
{{Training module quiz
  | question = <translate>#{assessment["question"].strip}</translate>
  | correct_answer_id = #{assessment["correct_answer_id"]}
#{assessment["answers"].map {|a|quiz_answer_params(a) }.join}
}}
<translate>
    QUIZ
  end

  def quiz_answer_params(answer)
    <<-PARAMS
  | answer_#{answer["id"]} = <translate>#{answer["text"].tr("\n", " ").strip}</translate>
  | explanation_#{answer["id"]} = <translate>#{answer["explanation"].tr("\n", " ").strip}</translate>
    PARAMS
  end
end


TrainingSlide.class_eval do
  def to_wiki_page
    <<-WIKITEXT
<noinclude><languages/></noinclude>
<translate>== #{title} ==

#{SlideConverter.new(self).to_wikitext}</translate>
    WIKITEXT
  end
end



modules[0..2].each do |tm|
  slides_array = tm.slide_slugs.map { |slug| { "slug" => slug } }
  module_id = 10000 + module_id_suffix
  # this goes into the module .json page on Meta
  module_json = {
    "id" => module_id,
    "slug" => tm.slug,
    "wiki_page" => "Training_modules/#{tm.slug}",
    "slides" => slides_array
  }.to_json
  puts module_json

  slide_number = 1
  # This goes into [[Training modules/dashboard/slides]]
  tm.slides.each do |slide|
    slide_id = (100 + module_id_suffix) * 100 + slide_number
    puts "* [[Training_modules/dashboard/slides/#{slide_id}-#{slide.slug}]]"
    slide_number += 1
  end;

  tm.slides.each do |slide|
    puts slide.slug
    puts "======================"
    puts slide.to_wiki_page
    puts "======================"
  end

  module_id_suffix += 1
end
puts "done"

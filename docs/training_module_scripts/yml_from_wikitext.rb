# Take wikitext for a training module, convert it into yml files.
require "#{Rails.root}/lib/training/wiki_slide_parser"
require 'fileutils'

module_number = 33
name = "Moving group work live"
ttc = "10 minutes"
description = "This module will guide you in moving your group's draft into Wikipedia proper."
suffix = '-group'
module_slug = 'moving-to-mainspace-group'
base_path = "#{Rails.root}/training_content/wiki_ed/slides/#{module_number}-#{module_slug}"
FileUtils.mkdir_p base_path

# input = <<-STUFF


# Write to a .yml file, return the id and slug base for populating the module.
def to_yml(wikitext, slide_id, suffix, base_path)
  parser = WikiSlideParser.new(wikitext)
  slug_base = parser.title.downcase.split(/\W+/).join('-')
  slug = "#{slide_id}-#{slug_base}#{suffix}"
  filename = "#{base_path}/#{slug}.yml"
  content = {
    'title' => parser.title,
    'content' => parser.content,
    'id' => slide_id
  }
  content.merge!({'assessment' => parser.quiz}) unless parser.quiz.blank?
  File.write filename, content.to_yaml
  return [slide_id, "#{slug_base}#{suffix}"]
end

# manually construct the module .yml file
def write_module_file(slide_slugs, module_number, module_slug, name, ttc, description)
  lines = []
  lines << "name: #{name}"
  lines << "id: #{module_number}"
  lines << "description: #{description}"
  lines << "estimated_ttc: #{ttc}"
  lines << "slides:"
  slide_slugs.each do |slug|
    lines << "  - slug: #{slug[1]} # #{slug[0]}"
  end
  path = "#{Rails.root}/training_content/wiki_ed/modules/#{module_slug}.yml"
  File.open(path, 'w+') do |file|
    file.puts(lines)
  end
end
  
# Take a single page of wikitext, and break it into level 2 sections, one section per slide
slide_wikitexts = input.split(/\n(?===)/);

i = 0
slide_slugs = []
# write all the slides and collect the slugs and ids
slide_wikitexts.each do |slide_wikitext|
  next if slide_wikitext.blank?
  i += 1
  padded_slide_count = "%02d" % i
  slide_id = "#{module_number}#{padded_slide_count}".to_i
  slide_slugs << to_yml(slide_wikitext, slide_id, suffix, base_path)
end;

# write the module yml file
write_module_file(slide_slugs, module_number, module_slug, name, ttc, description)

# Now fill in the missing fields in the module .yml file and reload the trainings

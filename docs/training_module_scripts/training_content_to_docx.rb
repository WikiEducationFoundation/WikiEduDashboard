 
 # Script to create a Google Doc for reviewing and preparing edits for training modules.

 def html_from_slide(slide)
  "\n<h2>#{slide.title}</h2><br />" <<
  PandocRuby.convert(slide.content, from: :markdown_github, to: :html) <<
  "<hr />" 
 end

 output = ''

TrainingModule.all.each do |tm|
  output += "--- <h1>Training Module ##{tm.id}: #{tm.name}</h1><br /> ---"
  output += "\n<p>#{tm.description}</p><br />"
  tm.slides.each do |slide|
    output += html_from_slide(slide)
  end
end

File.open('training_content.html', 'wb') { |file| file.write(output) }

# The pandoc conversion fails if a local asset file from the html does not exist.
# As of January 2025, the only case of this is the inline icon in slide 334-authorship-highlighting.yml
# Edit the html file to turn it into an absolute path — https://dashboard.wikiedu.org/assets/images/article-viewer.svg
# then proceed with the conversion.

`pandoc training_content.html --to docx --output trainings.docx`
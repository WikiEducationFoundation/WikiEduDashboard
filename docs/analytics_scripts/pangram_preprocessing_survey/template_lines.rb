# Renders Wiki Ed's exercise and sandbox preload templates as GetRevisionPlaintext
# would extract them, and writes their lines to <dir>/template_lines.json.
#   bin/rails runner template_lines.rb ~/pangram_preprocessing_survey
#
# A preload copies a template's wikitext minus <noinclude> sections, so each template's
# current wikitext is cut that way and parsed. Line matching against student texts
# then marks which lines are template text the student left in place.
require 'json'
require_dependency "#{Rails.root}/lib/wiki_api/article_content"

dir = File.expand_path(ARGV[0])
wiki = Wiki.get_or_create(language: 'en', project: 'wikipedia')
api = WikiApi.new(wiki)
content = WikiApi::ArticleContent.new(wiki)

titles = api.query(list: 'allpages', apnamespace: 10, apprefix: 'Dashboard.wikiedu.org',
                   aplimit: 500).data['allpages'].map { |p| p['title'] }
titles.reject! { |t| t.match?(%r{/(doc|sandbox|testcases|styles\.css)\z}) }

# GetRevisionPlaintext's HTML-to-text steps, applied to a parsed template.
extractor = GetRevisionPlaintext.allocate
to_lines = lambda do |html|
  cleaned = extractor.send(:remove_non_prose_html_elements, html)
  text = CGI.unescapeHTML(ActionView::Base.full_sanitizer.sanitize(cleaned))
  text.split("\n").map(&:strip).reject(&:empty?)
end

lines = {}
titles.each do |title|
  wikitext = api.get_page_content(title).to_s
  preloaded = wikitext.gsub(%r{<noinclude>.*?</noinclude>}m, '').gsub(%r{</?includeonly>}, '')
  next if preloaded.strip.empty?
  lines[title] = to_lines.call(content.parse_wikitext(preloaded))
  sleep 0.5
end
File.write(File.join(dir, 'template_lines.json'), JSON.pretty_generate(lines))
puts "#{lines.size} templates, #{lines.values.sum(&:size)} lines"

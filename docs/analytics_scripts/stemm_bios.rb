# Generate a list of article titles for biographies of historically excluded STEMM professionals,
# based on Wikidata queries and Wikipedia categories we compiled here:
# https://en.wikipedia.org/wiki/Wikipedia:Wiki_Education/Biographies

# run it like:
# bundle exec rails r docs/analytics_scripts/stemm_bios.rb 

require_relative "../../lib/importers/category_importer"

en_wiki = Wiki.find_by(language: 'en', project: 'wikipedia')

AA_BIOS_CAT = 'Category:21st-century African-American scientists'
aa_bios = CategoryImporter.new(en_wiki).mainspace_page_titles_for_category(AA_BIOS_CAT, 1) # depth 1


HLA_CAT = 'Category:Hispanic and Latino American scientists'
hla_bios = CategoryImporter.new(en_wiki).mainspace_page_titles_for_category(HLA_CAT, 4) # depth 4

# wikidata # 1
# wikidata # 2

def mainspace_links(page_title)
  query = {
    prop: 'links',
    plnamespace: 0,
    pllimit: 500,
    titles: page_title
  }
  links = []
  cont = true
  resp = WikiApi.new.query(query)

  until cont.nil? do
    page_id = resp.data['pages'].keys.first
    resp_links = resp.data.dig('pages', page_id, 'links')
    links << resp_links
    cont = resp['continue']
  
    resp = WikiApi.new.query(query.merge cont) if cont
  end

  links.flatten.map { |t| t['title'] }.uniq
end

american_women_stem_bios = mainspace_links 'Wikipedia:Wiki Education/Biographies/American women in STEM'
american_women_researcher_bios = mainspace_links 'Wikipedia:Wiki_Education/Biographies/American_women_researchers'

all_bios = aa_bios + hla_bios + american_women_stem_bios + american_women_researcher_bios

all_bios.uniq!

edited_articles = CSV.read('/home/sage/Downloads/spring_2024-wikiarticles.csv') + CSV.read('/home/sage/Downloads/fall_2024-wikiarticles.csv')
edited_articles.flatten!.map! { |t| t.gsub('_', ' ') }

edited_bios = edited_articles & all_bios

puts edited_bios.uniq.count

broadcom = CSV.read('/home/sage/Downloads/2025_broadcom.csv')

# This doesn't actually get uniqueness right, possibly because of line endings or something, so I used a spreadsheet
# to do final de-duplication.
puts (broadcom + edited_bios).uniq.count
puts (broadcom + edited_bios).sort
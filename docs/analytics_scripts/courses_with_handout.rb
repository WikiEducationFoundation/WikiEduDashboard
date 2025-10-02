# Get all the courses from a term that have a specific handout in the timeline

handout_link = 'https://wikiedu.org/biographies' # The Biographies handout
term = Campaign.find_by_slug 'fall_2025'
handout_courses = term.courses.select { |c| c.blocks.any? { |b| b.content&.include? handout_link } }

puts handout_courses.map(&:slug)
# frozen_string_literal: true
require 'net/http'
require_dependency "#{Rails.root}/lib/importers/user_importer"
require_dependency "#{Rails.root}/app/services/update_course_stats"
require_dependency "#{Rails.root}/lib/timeslice_manager"

def make_copy_of(url)
  # Get the main course data
  course_data = JSON.parse(Net::HTTP.get URI(url + '/course.json'))['course']

  # Check if it exists already
  existing_course = Course.find_by(slug: course_data['slug'])
  if existing_course.present?
    puts "Course #{existing_course.slug} already exists!"
    return existing_course
  end

  # Extract the attributes we want to copy
  params_to_copy = %w[school title term description start end subject slug timeline_start timeline_end type]
  copied_data = {}
  params_to_copy.each { |p| copied_data[p] = course_data[p] }
  home_wiki = Wiki.get_or_create(language: course_data['home_wiki']['language'], project: course_data['home_wiki']['project'])
  copied_data['home_wiki_id'] = home_wiki.id
  copied_data['passcode'] = 'passcode' # set an arbitrary passcode
  # Create the course
  course = Course.create!(
    copied_data
  )
  # Add the tracked wikis
  course_data['wikis'].each do |wiki_hash|
    wiki = Wiki.get_or_create(language: wiki_hash['language'], project: wiki_hash['project'])
    next if wiki.id == home_wiki.id # home wiki was automatically added already
    course.wikis << wiki
  end

  # Get the user list
  user_data = JSON.parse(Net::HTTP.get URI(url + '/users.json'))['course']['users']
  # Add the users to the course
  user_data.each do |user_hash|
    user = User.find_or_create_by!(username: user_hash['username'])
    CoursesUsers.create!(user_id: user.id, role: user_hash['role'], course_id: course.id)
  end

  # Get assignments
  assignments_data = JSON.parse(Net::HTTP.get URI(url + '/assignments.json'))['course']['assignments']
  # Replicate the assignments as available articles
  # This is a quick hack so stats are counted for an ArticleScopedProgram.
  # It assumes all assignments are on home wiki.
  assignments_data.each do |assignment_hash|
    Assignment.create(course_id: course.id, article_title: assignment_hash['article_title'], role: 0, wiki_id: home_wiki.id)
  end

  puts "Course #{url} copied! "
  puts "http://localhost:3000/courses/#{course.slug}"
  return course
end

# Set up some example data in the dashboard
def populate_dashboard
  puts "Setting up example courses..."
  example_courses = [
    'https://outreachdashboard.wmflabs.org/courses/Uffizi/WDG_-_AF_2018_Florence',
    'https://outreachdashboard.wmflabs.org/courses/QCA/Brisbane_QCA_ArtandFeminism_2018',
    'https://dashboard.wikiedu.org/courses/Stanford_Law_School/Advanced_Legal_Research_Winter_2020_(Winter)',
    'https://dashboard.wikiedu.org/courses/University_of_Nebraska-Lincoln/Jour303_Editing_for_Digital_Media_(Spring_2026)/',
    'https://dashboard.wikiedu.org/courses/DePaul_University/Modern_Languages_Capstone_Seminar_(Spring_2026)/',
    'https://dashboard.wikiedu.org/courses/Northeastern_University/ENGW3307_32275_Adv._Writing_in_the_Sciences_(Spring_2026)/',
    'https://dashboard.wikiedu.org/courses/North_Carolina_State_University/Chemistry_of_Materials_(Spring_2026)/',
    'https://dashboard.wikiedu.org/courses/University_of_Southern_California/Writing_340_-_Advanced_Writing_for_Arts_and_Humanities_-_3_(Spring_2026)/',
    'https://dashboard.wikiedu.org/courses/American_University_of_Armenia/Sophomore_Writing_II_(Spring_2026)/',
    'https://dashboard.wikiedu.org/courses/University_of_North_Carolina_at_Greensboro/ARH_372_African_Art_-_Modern_to_Contemporary_(Spring_2026)/',
    'https://dashboard.wikiedu.org/courses/University_of_Wisconsin-_Whitewater/Foundations_of_Professional_Writing_(Spring_2026)/',
    'https://dashboard.wikiedu.org/courses/American_University_of_Armenia/Sophomore_Writing_II_(Spring_2026)/',
    'https://dashboard.wikiedu.org/courses/California_State_University_Monterey_Bay/Biochemistry_I_(Spring_2026)/',
    'https://dashboard.wikiedu.org/courses/Montclair_State_Univ/Humanities_2_HYBRID_(Spring_2026)/',
    'https://dashboard.wikiedu.org/courses/UNC_Pembroke/Writing_in_Digital_Environments_(Spring_2026)/',
    'https://dashboard.wikiedu.org/courses/RPI/MTLE_4470_-_Biology_in_Materials_Science_(Spring_2026)/',
    'https://dashboard.wikiedu.org/courses/University_of_British_Columbia/Marine_Microbiology_(Spring_2026)/',
    'https://dashboard.wikiedu.org/courses/University_of_California,_Los_Angeles/Queer_Art_(Winter_2026)',
    'https://dashboard.wikiedu.org/courses/Saint_Leo_University/Scandal_and_Corruption_in_Politics_(Spring_2026)',
    'https://dashboard.wikiedu.org/courses/University_of_Texas_at_Arlington/Public_History_(Spring_2026)',
    'https://dashboard.wikiedu.org/courses/TCU_School_of_Medicine/TCU_SOM_Wikipedia_Elective_Spring_2026_Block_11B_(Spring_2026)',
    'https://dashboard.wikiedu.org/courses/University_of_California_Santa_Cruz/Systematic_Botany_of_Flowering_Plants_(Winter_2026)',
    'https://dashboard.wikiedu.org/courses/University_of_Maryland/Slavery_in_Latin_America_(Spring_2026)',
    'https://dashboard.wikiedu.org/courses/University_of_Washington/Geographies_of_Energy_and_Sustainability_(Winter_2026)',
    'https://dashboard.wikiedu.org/courses/University_of_Washington/Geographies_of_Energy_and_Sustainability_(Winter_2026)',
    'https://dashboard.wikiedu.org/courses/College_of_Wooster/Modern_Brazil_(Spring_2025)',
    'https://dashboard.wikiedu.org/courses/Iowa_State_University/Micro_3020H_Biology_of_Microorganisms_(Spring_2026)', 
    'https://dashboard.wikiedu.org/courses/Western_Michigan_University_Homer_Stryker_MD_School_of_Medicine/MEDU_9320-WikiProject_Medical_Translation-Spanish_(April_6,_2026)',
    'https://dashboard.wikiedu.org/courses/UCSB/Holocaust_and_other_genocides_in_European_history_(Winter_2026)',
    





  ]

  example_courses.each do |url|
    begin
      # Try to find or create the default campaign
      default_campaign = Campaign.find_or_create_by!(title: 'Default Campaign', slug: ENV['default_campaign'])

      # Attempt to make a copy of the course
      course = make_copy_of(url)

      # Check if the course already exists before associating it with the campaign
      if default_campaign.courses.exists?(slug: course.slug)
        Rails.logger.error("Course with slug #{course.slug} already exists in the campaign. Skipping...")
      else
        # Add the course to the campaign if it doesn't already exist
        default_campaign.courses << course
        puts "Getting data for #{course.slug}..."
        UpdateCourseStats.new(course)
      end
    rescue ActiveRecord::RecordInvalid => e
      # Handle specific error when record creation fails
      Rails.logger.error("Error processing course at #{url}: #{e.message}")
    rescue StandardError => e
      # Generic error handling for other issues
      Rails.logger.error("An error occurred for course at #{url}: #{e.message}")
    end
  end
end

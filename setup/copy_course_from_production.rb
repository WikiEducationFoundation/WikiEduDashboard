require 'net/http'

def make_copy_of(url)
  # Get the main course data
  course_data = JSON.parse(Net::HTTP.get URI(url + '/course.json'))['course']
  # Extract the attributes we want to copy
  params_to_copy = %w[school title term description start end subject slug timeline_start timeline_end type flags]
  copied_data = {}
  params_to_copy.each { |p| copied_data[p] = course_data[p] }
  home_wiki = Wiki.get_or_create(language: course_data['home_wiki']['language'], project: course_data['home_wiki']['project'])
  copied_data['home_wiki_id'] = home_wiki.id
  copied_data['passcode'] = 'passcode' # set an arbitrary passcode
  # Fix the update_logs in flags
  if copied_data['flags'].key?('update_logs')
    copied_data['flags']['update_logs'] = fix_update_logs_parsing(copied_data['flags']['update_logs'])
  end
  # Create the course
  course = Course.create!(
    copied_data
  )
  course.save

  # Add the tracked wikis
  course_data['wikis'].each do |wiki_hash|
    wiki = Wiki.get_or_create(language: wiki_hash['language'], project: wiki_hash['project'])
    next if wiki.id == home_wiki.id # home wiki was automatically added already
    course.wikis << wiki
  end

  # Add the tracked categories
  cat_data = JSON.parse(Net::HTTP.get URI(url + '/categories.json'))['course']['categories']
  cat_data.each do |cat_hash|
    wiki = Wiki.get_or_create(language: cat_hash['wiki']['language'], project: cat_hash['wiki']['project'])
    cat = Category.find_or_create_by!(
      depth: cat_hash['depth'],
      source: cat_hash['source'],
      name: cat_hash['name'],
      wiki: wiki
    )
    course.categories << cat
  end

  # Get the user list
  user_data = JSON.parse(Net::HTTP.get URI(url + '/users.json'))['course']['users']
  # Add the users to the course
  user_data.each do |user_hash|
    user = User.find_or_create_by!(username: user_hash['username'])
    CoursesUsers.create!(user_id: user.id, role: user_hash['role'], course_id: course.id)
  end
  pp 'Course created!'
  pp "http://localhost:3000/courses/#{course.slug}"
end

# When parsing update_logs from flags, keys are set as strings instead of integers
# This causes problems, so we need to force the keys to be integers.
def fix_update_logs_parsing(update_logs)
  fixed_update_logs = {}
  update_logs.each do |key, value|
    # Add the new log with same value but integer key
    fixed_update_logs[key.to_i] = value
  end
  fixed_update_logs
end

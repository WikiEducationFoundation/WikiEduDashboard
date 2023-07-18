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
  # Create the course
  course = Course.create!(
    copied_data
  )

  # Remove the update_logs, which cause problems due to conversion of integer keys to strings.
  course.flags.delete('update_logs')
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


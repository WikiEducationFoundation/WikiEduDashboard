# NOTE: Requires an existing user with a permissions level set to super admin.
# Create a course with students. Populate that course with tickets and
# replies. All tickets will be assigned to the first Super Admin found
# in the DB.

require 'faker'
require_dependency "#{Rails.root}/lib/importers/user_importer"

def populate_tickets_demo
  puts "Searching for super admin..."
  admin = User.find_by(permissions: User::Permissions::SUPER_ADMIN)
  error_msg = "Could not find a super admin. Please create a user with " \
              "super admin permissions before running this script."
  throw error_msg if admin.blank?
  puts "Found super admin #{admin.real_name || admin.username}!\n\n"
  
  puts "Searching for Ticketing Campaign..."
  campaign = Campaign.find_by(title: 'Ticketing Campaign')
  if campaign.blank?
    puts "The Ticketing Campaign was not found. Creating it now."
    campaign = create_campaign
    puts "Default campaign created!\n\n"
  else
    puts "Ticketing Campaign already exists!\n\n"
  end
  
  puts "Searching to see if demo course already exists..."
  course = Course.find_by(title: 'Intro to Color Theory (Ticketing Demo)')
  if course.blank?
    puts "The default demo ticketing course was not found. Creating one now."
    course = create_course
    course.campaigns << campaign
    puts "Default course created!\n\n"
  else
    puts "Default ticketing course already exists!\n\n"
  end

  puts "Searching for instructor..."
  instructor_username = 'Modernist'
  instructor = User.find_by(username: instructor_username)
  if instructor.blank?
    puts "No instructor found! Creating instructor..."
    user = UserImporter.new_from_username(instructor_username)
    CoursesUsers.find_or_create_by(user: user, course: course, role: 2)
    puts "Default instructor created!\n\n"
  else
    puts "Instructor already exists!\n\n"
  end

  student_usernames = %w[
    Telfordbuck
    Oshwah
    Srich32977
    DanielRigal
    Vsmith
  ]

  puts "Creating and/or associating students with course"
  courses_students = student_usernames.map do |username|
    student = User.find_by(username: username) || UserImporter.new_from_username(username)
    CoursesUsers.find_or_create_by(user: student, course: course, role: 0)
  end
  puts "Students created and/or associated with course!\n\n"

  puts "Re-seeding tickets and messages"
  course.tickets.delete_all
  5.times do
    course_student = courses_students.sample
    create_ticket_and_replies(course, course_student.user, admin)
  end
  puts "Seeding complete!"
end

private 

def create_campaign
  Campaign.create({
    slug: 'ticketing',
    title: 'Ticketing Campaign',
    default_course_type: 'BasicCourse'
  })
end

def create_course
  wiki = Wiki.get_or_create(language: 'en', project: 'wikipedia')
  Course.create({
    slug: 'Pratt_Institute/Intro_to_Color_Theory_(Ticketing_Demo)',
    title: 'Intro to Color Theory (Ticketing Demo)',
    term: 'Spring',
    school: 'Pratt Institute',
    start: 10.days.from_now,
    end: 90.days.from_now,
    home_wiki: wiki,
    passcode: 'abcdefg',
    needs_update: true
  })
end

def create_ticket_and_replies(course, sender, owner)
  ticket = TicketDispenser::Ticket.create({
    project: course,
    owner: owner
  })
  
  content = rand(3..6).times.inject('') do |acc|
    acc + Faker::Lorem.sentence(
      word_count: 3,
      supplemental: true,
      random_words_to_add: 10
    ) + " "
  end
  
  ticket.messages << TicketDispenser::Message.create({
    content: "<p>#{content.strip}</p>",
    sender: sender
  })
end

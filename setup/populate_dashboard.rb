# frozen_string_literal: true
require_dependency "#{Rails.root}/lib/importers/user_importer"
require_dependency "#{Rails.root}/app/services/update_course_stats"

# Set up some example data in the dashboard
def populate_dashboard
  puts "setting up example courses..."
  artfeminism_2018 = Campaign.find_by_slug('artfeminsism_2018') || Campaign.create(slug: 'artfeminism_2018',
                                                                                   title: 'Art+Feminism 2018',
                                                                                   default_course_type: 'Editathon',
                                                                                   default_passcode: 'no-passcode',
                                                                                   register_accounts: true)
  it_wiki = Wiki.get_or_create(language: 'it', project: 'wikipedia')
  florence_editathon = Course.find_by_slug('Uffizi/WDG_-_AF_2018_Florence') || Course.create(type: 'Editathon',
                                                                                             slug: 'Uffizi/WDG_-_AF_2018_Florence',
                                                                                             title: 'WDG - AF 2018 Florence',
                                                                                             school: 'Uffizi',
                                                                                             term: '',
                                                                                             passcode: '',
                                                                                             start: '2018-02-21'.to_date,
                                                                                             end: '2018-03-14'.to_date,
                                                                                             home_wiki: it_wiki,
                                                                                             needs_update: true)
  florence_editathon.campaigns << artfeminism_2018 if florence_editathon.campaigns.none?

  florence_facilitator = UserImporter.new_from_username('Solelu', it_wiki)
  CoursesUsers.find_or_create_by(user: florence_facilitator, course: florence_editathon, role: 1)

  florence_editors = %w[
    Krys.ro
    Apmsilva
    Krislane_de_Andrade
    Nikeknacksandsnacks
    Racheleb76
    Kaspo
    Nea.Lapini
    Chiara.toti
    MissDaae
    Ciucia60
    Lizwicks
    Katy1q77
    Matt.the.iconoclast
    Alejandeath
    Sherilovemusic
  ]

  florence_editors.each do |username|
    user = UserImporter.new_from_username(username, it_wiki)
    CoursesUsers.find_or_create_by(user: user, course: florence_editathon, role: 0)
  end

  en_wiki = Wiki.get_or_create(language: 'en', project: 'wikipedia')

  selfie = Article.find_or_create_by(title: 'Selfie', mw_page_id: 1, wiki: en_wiki)
  Assignment.find_or_create_by(course: florence_editathon, article: selfie, article_title: 'Selfie', role: 0)

  brisbane_editathon = Course.find_by_slug('QCA/Brisbane_QCA_ArtandFeminism_2018') || Course.create!(type: 'Editathon',
                                                                                                     slug: 'QCA/Brisbane_QCA_ArtandFeminism_2018',
                                                                                                     title: 'Brisbane QCA ArtandFeminism 2018',
                                                                                                     school: 'QCA',
                                                                                                     term: '',
                                                                                                     passcode: '',
                                                                                                     start: '2018-01-21'.to_date,
                                                                                                     end: '2018-03-14'.to_date,
                                                                                                     home_wiki: en_wiki,
                                                                                                     needs_update: true)

  brisbane_editathon.campaigns << artfeminism_2018 if brisbane_editathon.campaigns.none?

  brisbane_facilitator = UserImporter.new_from_username('LouiseRMayhew', en_wiki)
  CoursesUsers.find_or_create_by(user: brisbane_facilitator, course: brisbane_editathon, role: 1)

  brisbane_editors = %w[
    LouiseRMayhew
    Susan777
    Yizazy
    Kay_S_Lawrence
    Agoddard2
    Ejsnails
    KirstyKrasidakis
    Taana_R
    Charlottetheturtle
    Jessmariexox
    FriDaInformation
  ]

  brisbane_editors.each do |username|
    user = UserImporter.new_from_username(username, en_wiki)
    CoursesUsers.find_or_create_by(user: user, course: brisbane_editathon, role: 0)
  end

  ragesoss_example_course = Course.find_by_slug('test/Ragesoss_(test)') || Course.create!(type: 'ClassroomProgramCourse',
                                                                                          slug: 'test/Ragesoss_(test)',
                                                                                          title: 'Ragesoss',
                                                                                          school: 'test',
                                                                                          term: 'test',
                                                                                          passcode: 'abcdefgh',
                                                                                          start: '2017-07-04'.to_date,
                                                                                          end: '2020-12-31'.to_date,
                                                                                          home_wiki: en_wiki)
  ragesoss_example_course.campaigns << Campaign.first if ragesoss_example_course.campaigns.none?

  ragesoss = UserImporter.new_from_username('Ragesoss', en_wiki)
  CoursesUsers.find_or_create_by(user: ragesoss, course: ragesoss_example_course, role: 0)

  [florence_editathon, brisbane_editathon, ragesoss_example_course].each do |course|
    puts "getting data for #{course.slug}..."
    UpdateCourseStats.new(course)
  end
end

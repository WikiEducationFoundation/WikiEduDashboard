# frozen_string_literal: true
require_dependency "#{Rails.root}/lib/importers/user_importer"

# Set up some example data in the dashboard
def populate_dashboard
  artfeminism_2018 = Campaign.create!(slug: 'artfeminism_2018',
                                      title: 'Art+Feminism 2018',
                                      default_course_type: 'Editathon',
                                      default_passcode: 'no-passcode',
                                      register_accounts: true)
  it_wiki = Wiki.get_or_create(language: 'it', project: 'wikipedia')
  florence_editathon = Course.create!(type: 'Editathon',
                                      slug: 'Uffizi/WDG_-_AF_2018_Florence',
                                      title: 'WDG - AF 2018 Florence',
                                      school: 'Uffizi',
                                      term: '',
                                      passcode: '',
                                      start: '2018-02-21'.to_date,
                                      end: '2018-03-14'.to_date,
                                      home_wiki: it_wiki,
                                      needs_update: true)
  florence_editathon.campaigns << artfeminism_2018

  florence_facilitator = UserImporter.new_from_username('Solelu', it_wiki)
  CoursesUsers.create!(user: florence_facilitator, course: florence_editathon, role: 1)

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
    CoursesUsers.create!(user: user, course: florence_editathon, role: 0)
  end

  en_wiki = Wiki.get_or_create(language: 'en', project: 'wikipedia')

  selfie = Article.create!(title: 'Selfie', mw_page_id: 1, wiki: en_wiki)
  Assignment.create!(course: florence_editathon, article: selfie)

  brisbane_editathon = Course.create!(type: 'Editathon',
                                      slug: 'QCA/Brisbane_QCA_ArtandFeminism_2018',
                                      title: 'Brisbane QCA ArtandFeminism 2018',
                                      school: 'QCA',
                                      term: '',
                                      passcode: '',
                                      start: '2018-01-21'.to_date,
                                      end: '2018-03-14'.to_date,
                                      home_wiki: en_wiki,
                                      needs_update: true)

  brisbane_editathon.campaigns << artfeminism_2018

  brisbane_facilitator = UserImporter.new_from_username('LouiseRMayhew', en_wiki)
  CoursesUsers.create!(user: brisbane_facilitator, course: brisbane_editathon, role: 1)

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
    CoursesUsers.create!(user: user, course: brisbane_editathon, role: 0)
  end
end

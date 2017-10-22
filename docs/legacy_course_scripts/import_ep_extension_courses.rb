require "#{Rails.root}/lib/importers/user_importer"

class ImporterLegacy
  def initialize(campaign)
    @campaign = campaign
  end

  def course_data(course_id)
    wiki_api = MediawikiApi::Client.new Wiki.find(1).api_url
    params = {
      courseids: course_id,
      group: ''
    }
    wiki_api.action('liststudents', params).data['0']
  rescue
    puts "invalid course id: #{course_id}"
    raise
  end

  def add_student(student, course)
    user = UserImporter.new_from_username(student['username'], Wiki.find(1))
    JoinCourse.new(course: course, user: user, role: 0)
  end

  def add_instructor(instructor, course)
    user = UserImporter.new_from_username(instructor['username'], Wiki.find(1))
    JoinCourse.new(course: course, user: user, role: 1)
  end

  def create_course(id, salesforce_id)
    raise StandardError if Course.exists? id
    # return if Course.exists? id
    data = course_data(id)
    return unless data
    append = data['name'][-1, 1] != ')' ? ' ()' : ''
    pp data['name']
    course_slug_info = (data['name'] + append).split(%r{(.*)/(.*)\s\(([^\)]+)?\)})
    course_info = {}

    course_info['id'] = data['id']
    course_info['slug'] = data['name'].tr(' ', '_')
    course_info['school'] = course_slug_info[1]
    course_info['title'] = course_slug_info[2]
    course_info['term'] = course_slug_info[3] || ''
    course_info['start'] = data['start'].to_date
    course_info['end'] = data['end'].to_date
    course_info['type'] = 'LegacyCourse'
    course_info['home_wiki_id'] = 1
    course_info['flags'] = { ep_extension_course_id: id, salesforce_id: salesforce_id }

    course = Course.create!(course_info)
    course.campaigns << @campaign

    data['students'].each do |student|
      add_student(student, course)
    end
    data['instructors'].each do |instructor|
      add_instructor(instructor, course)
    end
  rescue
    pp course_info
    raise
  end
end

# invalid: [72, 'a0f1a000000Mejl']
spring_2013 = Campaign.find_by(slug: 'spring_2013')
spring_2013_courses = [4, 'a0f1a000000Meje'], [5, 'a0f1a000000Merv'], [6, 'a0f1a000000Meji'], [8, 'a0f1a000000Meix'], [9, 'a0f1a000000Meiz'], [10, 'a0f1a000000MesH'], [11, 'a0f1a000000MesG'], [19, 'a0f1a000000Mek3'], [20, 'a0f1a000000Mero'], [23, 'a0f1a000000Mery'], [27, 'a0f1a000000Merg'], [28, 'a0f1a000000MesC'], [30, 'a0f1a000000MejT'], [31, 'a0f1a000000MesI'], [32, 'a0f1a000000Merk'], [33, 'a0f1a000000Mes2'], [34, 'a0f1a000000Mejm'], [35, 'a0f1a000000Merf'], [37, 'a0f1a000000Merq'], [38, 'a0f1a000000Meip'], [39, 'a0f1a000000Meiq'], [41, 'a0f1a000000Merx'], [43, 'a0f1a000000MesF'], [44, 'a0f1a000000Mejo'], [45, 'a0f1a000000Mej0'], [46, 'a0f1a000000MejO'], [47, 'a0f1a000000MejP'], [48, 'a0f1a000000Merr'], [49, 'a0f1a000000Mes1'], [50, 'a0f1a000000MejI'], [52, 'a0f1a000000MejK'], [55, 'a0f1a000000Meig'], [56, 'a0f1a000000Meii'], [57, 'a0f1a000000Meij'], [58, 'a0f1a000000Mes5'], [60, 'a0f1a000000Mejs'], [62, 'a0f1a000000Mek5'], [63, 'a0f1a000000Merz'], [64, 'a0f1a000000Mejw'], [65, 'a0f1a000000Mert'], [66, 'a0f1a000000Merm'], [68, 'a0f1a000000MesD'], [69, 'a0f1a000000Merp'], [70, 'a0f1a000000MejX'], [76, 'a0f1a000000Merh'], [77, 'a0f1a000000Meri'], [78, 'a0f1a000000Merj'], [79, 'a0f1a000000Merw'], [81, 'a0f1a000000MesB'], [83, 'a0f1a000000Merl'], [84, 'a0f1a000000Mek0'], [85, 'a0f1a000000Mern'], [86, 'a0f1a000000Mejf'], [88, 'a0f1a000000Mes8'], [90, 'a0f1a000000Mes6'], [93, 'a0f1a000000MesA'], [94, 'a0f1a000000Mej1'], [96, 'a0f1a000000Mes4'], [97, 'a0f1a000000Mejn'], [99, 'a0f1a000000Mejx'], [100, 'a0f1a000000Mejy'], [101, 'a0f1a000000MesE'], [102, 'a0f1a000000Mek1'], [103, 'a0f1a000000Mes0'], [104, 'a0f1a000000Mers'], [105, 'a0f1a000000Mes9'], [110, 'a0f1a000000Mes7'], [111, 'a0f1a000000Meru'], [114, 'a0f1a000000Mes3']
imp = ImporterLegacy.new(spring_2013)
spring_2013_courses.each { |course_ids| imp.create_course course_ids[0], course_ids[1] }

fall_2013 = Campaign.find_by(slug: 'fall_2013')
fall_2013_courses = [119, 'a0f1a000000MejC'], [125, 'a0f1a000000MejD'], [132, 'a0f1a000000MesJ'], [135, 'a0f1a000000Meik'], [136, 'a0f1a000000MesN'], [138, 'a0f1a000000Mesd'], [139, 'a0f1a000000Meir'], [140, 'a0f1a000000Meis'], [141, 'a0f1a000000MejU'], [142, 'a0f1a000000Mesf'], [143, 'a0f1a000000Mesq'], [144, 'a0f1a000000Mejg'], [145, 'a0f1a000000Mesr'], [146, 'a0f1a000000MesW'], [150, 'a0f1a000000Mesc'], [151, 'a0f1a000000MesQ'], [152, 'a0f1a000000Mest'], [153, 'a0f1a000000Mesk'], [154, 'a0f1a000000Mesj'], [155, 'a0f1a000000MesM'], [157, 'a0f1a000000Mesn'], [159, 'a0f1a000000MesP'], [160, 'a0f1a000000MesL'], [161, 'a0f1a000000MesU'], [162, 'a0f1a000000Mej2'], [163, 'a0f1a000000Mej4'], [165, 'a0f1a000000Mesv'], [168, 'a0f1a000000Mejt'], [172, 'a0f1a000000MesK'], [178, 'a0f1a000000MesR'], [183, 'a0f1a000000MejQ'], [184, 'a0f1a000000Mejj'], [185, 'a0f1a000000Mesb'], [186, 'a0f1a000000Meih'], [187, 'a0f1a000000MejJ'], [188, 'a0f1a000000MesZ'], [190, 'a0f1a000000Mesl'], [191, 'a0f1a000000MejL'], [193, 'a0f1a000000Mesp'], [194, 'a0f1a000000Meso'], [195, 'a0f1a000000Meja'], [196, 'a0f1a000000Mejc'], [197, 'a0f1a000000Mesh'], [198, 'a0f1a000000MejV'], [199, 'a0f1a000000Mej5'], [200, 'a0f1a000000Mess'], [201, 'a0f1a000000Mek2'], [205, 'a0f1a000000Mese'], [207, 'a0f1a000000Mejq'], [208, 'a0f1a000000MesO'], [212, 'a0f1a000000Mesg'], [213, 'a0f1a000000MesV'], [218, 'a0f1a000000Mej6'], [219, 'a0f1a000000Mesi'], [220, 'a0f1a000000Mesm'], [221, 'a0f1a000000Mesu'], [222, 'a0f1a000000Mej7'], [223, 'a0f1a000000MesT'], [225, 'a0f1a000000Mesa'], [226, 'a0f1a000000MesS'], [232, 'a0f1a000000Meju'], [234, 'a0f1a000000Mejb']
imp = ImporterLegacy.new(fall_2013)
fall_2013_courses.each { |course_ids| imp.create_course course_ids[0], course_ids[1] }

# invalid: [167, 'a0f1a000000Met2']
# main already in a campaign: [77, 'a0f1a000000MemQ'], [161, 'a0f1a000000Mejp']
spring_2014 = Campaign.find_by(slug: 'spring_2014')
spring_2014_courses = [241, 'a0f1a000000MejE'], [244, 'a0f1a000000Met8'], [248, 'a0f1a000000Mek6'], [250, 'a0f1a000000MejF'], [251, 'a0f1a000000Met5'], [252, 'a0f1a000000Met0'], [253, 'a0f1a000000Mesy'], [254, 'a0f1a000000MejW'], [255, 'a0f1a000000Mek4'], [256, 'a0f1a000000Met1'], [257, 'a0f1a000000Meie'], [258, 'a0f1a000000MetD'], [262, 'a0f1a000000MetA'], [264, 'a0f1a000000Meit'], [265, 'a0f1a000000Meiu'], [266, 'a0f1a000000Meio'], [267, 'a0f1a000000Mejh'], [268, 'a0f1a000000Meil'], [269, 'a0f1a000000Meif'], [270, 'a0f1a000000MetB'], [271, 'a0f1a000000MetE'], [272, 'a0f1a000000MejY'], [273, 'a0f1a000000MejZ'], [274, 'a0f1a000000Met3'], [275, 'a0f1a000000Meiy'], [276, 'a0f1a000000MemW'], [277, 'a0f1a000000MemO'], [278, 'a0f1a000000MejG'], [279, 'a0f1a000000Met6'], [282, 'a0f1a000000Meiw'], [285, 'a0f1a000000Mejr'], [286, 'a0f1a000000Mej8'], [287, 'a0f1a000000Met9'], [288, 'a0f1a000000Mej9'], [289, 'a0f1a000000MejA'], [290, 'a0f1a000000Meid'], [291, 'a0f1a000000MejM'], [292, 'a0f1a000000MejN'], [293, 'a0f1a000000MemX'], [294, 'a0f1a000000Mej3'], [295, 'a0f1a000000Mejd'], [296, 'a0f1a000000MemU'], [300, 'a0f1a000000Mejz'], [301, 'a0f1a000000Meim'], [304, 'a0f1a000000Meic'], [306, 'a0f1a000000Mesw'], [308, 'a0f1a000000MejR'], [311, 'a0f1a000000Mesx'], [315, 'a0f1a000000MemS'], [316, 'a0f1a000000Mejv'], [319, 'a0f1a000000Mein'], [320, 'a0f1a000000MemT'], [323, 'a0f1a000000MemR'], [324, 'a0f1a000000Mejk'], [325, 'a0f1a000000Met7'], [327, 'a0f1a000000MemV'], [329, 'a0f1a000000Mesz'], [330, 'a0f1a000000MeiS'], [332, 'a0f1a000000MejS'], [333, 'a0f1a000000MetC'], [334, 'a0f1a000000MemP'], [338, 'a0f1a000000MeiY'], [341, 'a0f1a000000MeiZ'], [342, 'a0f1a000000Meib'], [345, 'a0f1a000000Meia']
imp = ImporterLegacy.new(spring_2014)
spring_2014_courses.each { |course_ids| imp.create_course course_ids[0], course_ids[1] }

spring_2013.courses.update_all(needs_update: true)
fall_2013.courses.update_all(needs_update: true)
spring_2014.courses.update_all(needs_update: true)


# After the updates finish
spring_2013.courses.each { |course| PushCourseToSalesforce.new(course) if course.flags[:salesforce_id] }
fall_2013.courses.each { |course| PushCourseToSalesforce.new(course) if course.flags[:salesforce_id] }
spring_2014.courses.each { |course| PushCourseToSalesforce.new(course) if course.flags[:salesforce_id] }

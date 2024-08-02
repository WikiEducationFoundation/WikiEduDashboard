# frozen_string_literal: true
#= Copy course from another server
# rubocop:disable Metrics/ClassLength
class CopyCourse
  def initialize(url:, user_data:)
    @url = url
    @user_data = user_data
  end

  def make_copy
    @course_data = retrieve_course_data
    copy_main_course_data
    add_tracked_wikis
    @cat_data = retrieve_categories_data
    copy_tracked_categories_data
    copy_users_data if @user_data.present? && @user_data != '0'
    @training_modules = retrieve_all_training_modules
    @timeline_data = retrieve_timeline_data
    copy_timeline_data
    return { course: @course, error: nil }
  rescue ActiveRecord::RecordNotUnique
    return { course: Course.find_by(slug: @course_data['slug']), error: nil }
  rescue ActiveRecord::RecordInvalid, StandardError => e
    return { course: nil, error: e.message }
  end

  private

  def copy_main_course_data
    # Extract the attributes we want to copy
    params_to_copy = %w[school title term description start end subject slug timeline_start
                        timeline_end type flags weekdays]
    modify_course_slug
    copied_data = {}
    params_to_copy.each { |p| copied_data[p] = @course_data[p] }
    change_type(copied_data) # Changes the course type of certain courses
    @home_wiki = Wiki.get_or_create(language: @course_data['home_wiki']['language'],
                                    project: @course_data['home_wiki']['project'])
    copied_data['home_wiki_id'] = @home_wiki.id
    copied_data['passcode'] = GeneratePasscode.call # set a random passcode
    if copied_data['flags'].key?('update_logs')
      copied_data['flags']['update_logs'] =
        fix_update_logs_parsing(copied_data['flags']['update_logs'])
    end
    # Create the course
    @course = Course.create!(copied_data)
  end

  def change_type(copied_data)
    if @course_data['type'] == "ClassroomProgramCourse" ||
       @course_data['type'] == "FellowsCohort" ||
       @course_data['type'] == "VisitingScholarship"
      copied_data['type'] = "BasicCourse"
    end
  end

  def modify_course_slug
    @course_data['term'] = "COPIED FROM #{@course_data['term']}"
    @course_data['slug'] =
      "#{@course_data['school']}/#{@course_data['title']}_(#{@course_data['term']})".tr(' ', '_')
  end

  # When parsing update_logs from flags, keys are set as strings instead of integers
  # This causes problems, so we need to force the keys to be integers.
  def fix_update_logs_parsing(update_logs)
    update_logs.transform_keys(&:to_i)
  end

  def add_tracked_wikis
    @course_data['wikis'].each do |wiki_hash|
      wiki = Wiki.get_or_create(language: wiki_hash['language'], project: wiki_hash['project'])
      next if wiki.id == @home_wiki.id # home wiki was automatically added already
      @course.wikis << wiki
    end
  end

  def copy_tracked_categories_data
    @cat_data.each do |cat_hash|
      wiki = Wiki.get_or_create(language: cat_hash['wiki']['language'],
                                project: cat_hash['wiki']['project'])
      cat = Category.find_or_create_by!(depth: cat_hash['depth'], source: cat_hash['source'],
                                        name: cat_hash['name'], wiki:)
      @course.categories << cat
    end
  end

  def copy_users_data
    retrieve_users_data
    @users_data.each do |user_hash|
      user = User.find_or_create_by!(username: user_hash['username'])
      CoursesUsers.create!(user_id: user.id, role: user_hash['role'], course_id: @course.id)
    end
  end

  def get_request(path)
    sanitized_url = sanitize_url(@url)
    uri = URI(sanitized_url + path)
    response = Net::HTTP.get_response(uri)
    raise "Error getting data from #{uri}" unless response.is_a?(Net::HTTPSuccess)
    response
  end

  def sanitize_url(input_url)
    uri = URI.parse(input_url)
    path_segments = uri.path.split('/')
    desired_path = path_segments[0..3].join('/')
    sanitized_url = "https://#{uri.host}#{desired_path}"
    return sanitized_url
  end

  def retrieve_course_data
    response = get_request('/course.json')
    JSON.parse(response.body)['course']
  end

  def retrieve_timeline_data
    response = get_request('/timeline.json')
    JSON.parse(response.body)['course']
  end

  def retrieve_categories_data
    response = get_request('/categories.json')
    JSON.parse(response.body)['course']['categories']
  end

  def retrieve_users_data
    response = get_request('/users.json')
    @users_data = JSON.parse(response.body)['course']['users']
  end

  def retrieve_all_training_modules
    @selected_dashboard = Features.wiki_ed? ? 'https://outreachdashboard.wmflabs.org' : 'https://dashboard.wikiedu.org'
    dashboard_uri = URI.parse(@selected_dashboard + '/training_modules.json')
    response = Net::HTTP.get_response(dashboard_uri)
    return [] unless response.is_a?(Net::HTTPSuccess)

    data = JSON.parse(response.body)
    data['training_modules'] || []
  end

  # Copy the timeline
  def copy_timeline_data
    @timeline_data['weeks'].each do |week_data|
      week = Week.create!(course_id: @course.id,
                          title: week_data['title'], order: week_data['order'])
      copy_blocks(week, week_data['blocks'])
    end
  end

  def copy_blocks(week, blocks)
    blocks.each do |block_data|
      block = Block.create!(content: block_data['content'], title: block_data['title'],
                            week_id: week.id, order: block_data['order'], kind: block_data['kind'])
      update_block_content(block, block_data)
    end
  end

  def update_block_content(block, block_data)
    headings = %w[Training Exercise Discussion].map do |title|
      "<h4 class=\"timeline-exercise\">#{title}</h4>\n"
    end
    content_additions = { 0 => '', 1 => '', 2 => '' }

    block_data['training_module_ids']&.each do |id|
      data, kind = copy_training_modules(id)
      content_additions[kind] += data
    end

    final_content = block.content || ''
    content_additions.reverse_each do |kind, addition|
      final_content = headings[kind] + addition + final_content unless addition.empty?
    end

    block.update!(content: final_content)
  end

  def copy_training_modules(module_id)
    matching_module = @training_modules.find { |mod| mod['id'] == module_id }
    return ['', nil] unless matching_module

    training_library = @course_data['training_library_slug']
    module_url = "#{@selected_dashboard}/training/#{training_library}/#{matching_module['slug']}"

    html_block = "<a href=\"#{module_url}\" class=\"training-module\">#{matching_module['name']}
      <i class=\"icon icon-rt_arrow_purple_training_module\"></i></a>"

    return html_block, matching_module['kind']
  end
end
# rubocop:enable Metrics/ClassLength

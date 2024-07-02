# frozen_string_literal: true
#= Copy course from another server
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
    if @user_data.present? && @user_data != '0'
      @users_data = retrieve_users_data
      copy_users_data
    end
    @timeline_data = retrieve_timeline_data
    copy_timeline_data
    return { course: @course, error: nil }
  rescue ActiveRecord::RecordInvalid, StandardError => e
    return { course: nil, error: e.message }
  end

  private

  def copy_main_course_data
    # Extract the attributes we want to copy
    params_to_copy = %w[school title term description start end subject slug timeline_start
                        timeline_end type flags weekdays]
    copied_data = {}
    params_to_copy.each { |p| copied_data[p] = @course_data[p] }
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
      cat = Category.find_or_create_by!(
        depth: cat_hash['depth'],
        source: cat_hash['source'],
        name: cat_hash['name'],
        wiki:
      )
      @course.categories << cat
    end
  end

  def copy_users_data
    @users_data.each do |user_hash|
      user = User.find_or_create_by!(username: user_hash['username'])
      CoursesUsers.create!(user_id: user.id, role: user_hash['role'], course_id: @course.id)
    end
  end

  def get_request(path)
    uri = URI(@url + path)
    response = Net::HTTP.get_response(uri)
    raise "Error getting data from #{uri}" unless response.is_a?(Net::HTTPSuccess)
    response
  end

  def retrieve_course_data
    response = get_request('/course.json')
    JSON.parse(response.body)['course']
  end

  def retrieve_timeline_data
    response = get_request('/timeline.json')
    JSON.parse(response.body)['course']
  end

  def copy_timeline_data
    @timeline_data['weeks'].each do |week_data|
      week = Week.new(
        course_id: @course.id,
        title: week_data['title'],
        order: week_data['order']
      )
      week.save!
      week_data['blocks'].each do |block_data|
        block_attributes = {
          week_id: week.id, title: block_data['title'], content: block_data['content'],
          order: block_data['order'], kind: block_data['kind']
        }
        block = Block.new(block_attributes)
        block.save!
      end
    end
  end

  def retrieve_categories_data
    response = get_request('/categories.json')
    JSON.parse(response.body)['course']['categories']
  end

  def retrieve_users_data
    response = get_request('/users.json')
    JSON.parse(response.body)['course']['users']
  end
end

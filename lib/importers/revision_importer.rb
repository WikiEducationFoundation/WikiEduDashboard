require "#{Rails.root}/lib/replica"

#= Imports and updates revisions from Wikipedia into the dashboard database
class RevisionImporter
  ################
  # Entry points #
  ################

  ##############
  # API Access #
  ##############  
  def self.update_all_revisions(courses=nil, all_time=false)
    results = []
    courses = [courses] if courses.is_a? Course
    courses ||= all_time ? Course.all : Course.current
    courses.each do |c|
      results += get_revisions_for_course(c)
    end

    import_revisions(results)

    result_ids = results.map do |_a_id, a|
      a['revisions'].map { |r| r['id'] }
    end
    result_ids = result_ids.flatten
    result_revs = Revision.where(id: result_ids)

    ArticlesCourses.update_from_revisions result_revs
  end

  # Given a Course, get new revisions for the users in that course.
  def self.get_revisions_for_course(c)
    results = []
    return results if c.students.empty?
    start = c.start.strftime('%Y%m%d')
    end_date = c.end.strftime('%Y%m%d')
    new_users = c.users.role('student').where(revision_count: 0)

    old_users = c.students - new_users

    unless new_users.empty?
      results += get_revisions(new_users, start, end_date)
    end

    unless old_users.empty?
      first_rev = c.revisions.order('date DESC').first
      start = first_rev.date.strftime('%Y%m%d') unless first_rev.blank?
      results += get_revisions(old_users, start, end_date)
    end
    results
  end

  # Get revisions made by a set of users between two dates.
  def self.get_revisions(users, start, end_date)
    Utils.chunk_requests(users, 40) do |block|
      Replica.get_revisions block, start, end_date
    end
  end
  ###########
  # Helpers #
  ###########
  def self.import_revisions(data)
    # Add/update articles
    data.each_slice(8000) do |sub_data|
      articles, revisions = [], []

      sub_data.each do |_a_id, a|
        article = Article.new(id: a['article']['id'])
        article.update(a['article'], false)
        articles.push article

        a['revisions'].each do |r|
          revision = Revision.new(id: r['id'])
          revision.update(r, false)
          revisions.push revision
        end
      end

      Article.import articles
      Revision.import revisions
    end

    ActiveRecord::Base.transaction do
      Assignment.where(article_id: nil).each do |a|
        article = Article.find_by(title: a.article_title)
        a.article_id = article.nil? ? nil : article.id
        a.save
      end
    end
  end
end

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
      next if c.students.empty?

      new_users = c.users.role('student').where(revision_count: 0)

      old_users = c.students - new_users
      unless old_users.empty?
        start = c.revisions.order('date DESC').first.date.strftime('%Y%m%d')
        results += Utils.chunk_requests(old_users, 40) do |block|
          Replica.get_revisions block, start, c.end.strftime('%Y%m%d')
        end
      end

      unless new_users.empty?
        start = c.start.strftime('%Y%m%d')
        results += Utils.chunk_requests(new_users, 40) do |block|
          Replica.get_revisions block, start, c.end.strftime('%Y%m%d')
        end
      end
    end

    import_revisions(results)

    result_ids = results.map do |_a_id, a|
      a['revisions'].map { |r| r['id'] }
    end
    result_ids = result_ids.flatten
    result_revs = Revision.where(id: result_ids)

    ArticlesCourses.update_from_revisions result_revs
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

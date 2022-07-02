# frozen_string_literal: true

class UpdateNamespaceStats

  def initialize(course)
    @course = course
    update_stats
  end

  def update_stats
    namespaces = @course.tracked_namespaces
    stats = {}
    namespaces.each { |ns| 
      stats[ns] = {
        'edited_count': edited_articles_count(ns),
        'new_count': new_articles_count(ns),
        'revision_count': revision_count(ns),
        'user_count': user_count(ns),
        'word_count': word_count(ns),
        'references_count': references_count(ns),
        'views_count': views_count(ns)
      }}
    
    crs_stat = CourseStat.find_by(course_id: @course.id) || CourseStat.create(course_id: @course.id)
    crs_stat.stats_hash['wiki_name'] = stats
    crs_stat.save
  end

  def live_revisions(ns)
    @course.tracked_revisions(ns).live
  end

  def edited_articles_count(ns)
		@course.edited_articles_courses(ns).count
	end

  def new_articles_count(ns)
    @course.new_articles_courses(ns).count
  end

  def revision_count(ns)
    revisions = live_revisions(ns)
    revisions.size
  end

  def user_count(ns)
    revisions = live_revisions(ns)
    revisions.distinct.pluck(:user_id).count
  end

  def word_count(ns)
    revisions = live_revisions(ns)
    character_sum = revisions.where('characters >= 0').sum(:characters) || 0
    WordCount.from_characters(character_sum)
  end

  def references_count(ns)
    revisions = live_revisions(ns)
    revisions.sum(&:references_added)
  end

  def views_count(ns)
    @course.edited_articles_courses(ns).sum(:view_count)
  end

end
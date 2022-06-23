# frozen_string_literal: true

class UpdateNamespaceStats
	def initialize(course)
		@course = course
		tracked_namespaces = get_tracked_namespace
		tracked_namespaces.each { |nm| 
			update_stats(nm)
		}
	end

	def get_tracked_namespace
		# @course.tracked_namespaces
		return [102] # cookbook namespace
	end

	def update_stats(nm)
		stats = { 
			'cookbook': {
				'edited_count': edited_articles_count(nm),
				'new_count': new_articles_count(nm),
				'revision_count': revision_count(nm),
				'user_count': user_count(nm),
				'word_count': word_count(nm),
				'references_count': references_count(nm),
				'views_count': views_count(nm)
		}}
		puts 'Cookbook stats -'
		puts stats
		crs_stat = CourseStat.find_by(course_id: @course.id) || CourseStat.create(course_id: @course.id)
		crs_stat.stats_hash[wikibook.domain] = stats
		crs_stat.save
	end

	def wikibook
    Wiki.get_or_create(language: 'en', project: 'wikibooks')
  end

	# Gets revisions according to namespace and wikis for a course
	# Returns a joint model of revisions and articles
	def namespace_articles_revisions(nm)
		course_wikis_ids = @course.wikis.pluck(:id)
		articles_revisions = @course.revisions.where(wiki_id: course_wikis_ids).joins(:article)
		articles_revisions.where(articles: {namespace: nm})
	end

	def edited_articles_count(nm)
		revisions = namespace_articles_revisions(nm)
		revisions.pluck("DISTINCT article_id").size
	end

	def new_articles_count(nm)
		revisions = namespace_articles_revisions(nm).where(new_article: true)
		revisions.pluck("DISTINCT article_id").size
	end

	def revision_count(nm)
		revisions = namespace_articles_revisions(nm).live
		revisions.size
	end

	def user_count(nm)
		revisions = namespace_articles_revisions(nm).group(:user_id)
		revisions.pluck(:user_id).size
	end

	def word_count(nm)
		revisions = namespace_articles_revisions(nm).live
		# from courses_users
		character_sum = revisions
      .where('characters >= 0')
      .sum(:characters) || 0
		WordCount.from_characters(character_sum)
	end

	def references_count(nm)
		revisions = namespace_articles_revisions(nm).live
		# from courses_users
		revisions.sum(&:references_added)
	end

	def views_count(nm)
		revisions = namespace_articles_revisions(nm)
		articles_revisions_ids = revisions.pluck(:article_id)

		count = 0
		articles_revisions_ids.each { |id|
			rev = revisions.where(article_id: id)
			article = Article.where(id: id)[0]
			break if rev.blank?
			break if article.average_views.nil?
			days = (Time.now.utc.to_date - rev.min_by(&:date).date.to_date).to_i
    	count = count + days * article.average_views
		}
		count
	end
end

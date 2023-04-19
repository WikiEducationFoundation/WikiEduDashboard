# frozen_string_literal: true

class PageviewSpikeMailerPreview < ActionMailer::Preview
	def message_to_wiki_ed_staff
		PageviewSpikeMailer.email(example_article_course, example_staffer)
	end
  
	private

	def example_article_course
		course = Course.new(title: "Apostrophe's Folly", slug: "School/Apostrophe's_Folly_(Spring_2019)")
		article = Article.new(title: "King's Gambit")
		ArticlesCourses.new(article: article, course: course)
	end
  
	def example_staffer
		[User.new(email: 'sage@example.com', username: 'Sage (Wiki Ed)', real_name: 'Sage Ross')]
	end
end
  
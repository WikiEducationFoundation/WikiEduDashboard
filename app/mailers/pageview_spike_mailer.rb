# frozen_string_literal: true

class PageviewSpikeMailer < ApplicationMailer
	def self.send_spike_alert_email(article_course)
		return unless Features.email?
		wiki_ed_staff = article_course.course.courses_users.where(role: CoursesUsers::Roles::WIKI_ED_STAFF_ROLE)
		email(article_course, wiki_ed_staff).deliver_now
	end

	def email(article_course, staff)
		@course = article_course.course
		@article = article_course.article
		@course_link = "https://#{ENV['dashboard_url']}/courses/#{@course.slug}"
		@articles_link = "#{@course_link}/articles"
		mail(to: staff.map(&:email),
		     subject: "Notable spike in the pageviews count of article.")
	end
end

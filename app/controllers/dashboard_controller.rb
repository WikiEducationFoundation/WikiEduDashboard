# frozen_string_literal: true

require 'rss'

#= Controller for dashboard functionality
class DashboardController < ApplicationController
  respond_to :html

  def index
    unless current_user
      redirect_to root_path
      return
    end
    set_blog_posts if Features.wiki_ed?
    set_admin_courses_if_admin
    @pres = DashboardPresenter.new(current_courses, past_courses,
                                   @submitted, @strictly_current, current_user)
  end

  private

  BLOG_FEED_URL = 'https://wikiedu.org/feed'
  def set_blog_posts
    @blog_posts = Rails.cache.fetch('posts', expires_in: 1.day) do
      RSS::Parser.parse(BLOG_FEED_URL, false).items
    end
  # Rescue 404 errors, in case wikiedu.org is down.
  rescue OpenURI::HTTPError, SocketError
    @blog_posts = []
  end

  def set_admin_courses_if_admin
    @submitted = []
    @strictly_current = []

    return unless current_user.admin?
    @submitted = Course.submitted_but_unapproved
    @strictly_current = current_user.courses.strictly_current
  end

  def current_courses
    current_user.courses.current_and_future
  end

  def past_courses
    # Admins see course lists based strictly on start and end dates.
    # Other users have course lists based on the 'current' scope, which
    # include courses that have just ended.
    # This makes sure the combination of displayed courses includes all courses,
    # without leaving some stuck in between being past and current.
    if current_user.admin?
      current_user.courses.where('end <= ?', Date.today).order(end: :desc)
    else
      current_user.courses.archived.order(end: :desc)
    end
  end
end

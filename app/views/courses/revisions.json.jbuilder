# frozen_string_literal: true

json.course do
  revisions = if @course_scoped
                @course.tracked_revisions
                       .eager_load(:user, :wiki).includes(article: :wiki)
                       .order(date: :desc).limit(@limit)
              else
                @course.recent_revisions
                       .eager_load(:user, :wiki).includes(article: :wiki)
                       .order(date: :desc).limit(@limit)
              end

  json.revisions(revisions) do |rev|
    json.call(rev, :id, :url, :characters, :date, :user_id,
              :mw_rev_id, :mw_page_id, :wiki)
    json.call(rev.article, :rating)
    json.article_url rev.article.url
    json.title rev.article.full_title
    json.references_added rev.references_added
    json.rating_num rating_priority(rev.article.rating)
    json.pretty_rating rating_display(rev.article.rating)
    json.revisor rev.user.username
  end
end

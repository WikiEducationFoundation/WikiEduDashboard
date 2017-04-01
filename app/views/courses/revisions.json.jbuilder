# frozen_string_literal: true

json.course do
  json.revisions @course.revisions.live
    .eager_load(:user, :wiki).includes(article: :wiki)
    .order(date: :desc).limit(50) do |rev|

    json.call(rev, :id, :url, :characters, :date, :user_id, :mw_rev_id, :mw_page_id, :wiki)
    json.call(rev.article, :rating)
    json.article_url article_url(rev.article)
    json.title full_title(rev.article)
    json.rating_num rating_priority(rev.article.rating)
    json.pretty_rating rating_display(rev.article.rating)
    json.revisor rev.user.username
  end
end

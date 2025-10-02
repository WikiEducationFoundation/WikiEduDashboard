# Add links to prior alerts, for ones created before this happened automatically

same_user = AiEditAlert.all.group(:course_id, :user_id).having('count(*) > 1').count
same_user.each_key do |(courseid, userid)|
  alerts = AiEditAlert.where(course_id: courseid, user_id: userid)
  alerts.each_cons(2) do |first_alert, second_alert|
    second_alert.details[:prior_alert_for_user] = first_alert.id
    second_alert.save
  end
end

same_page = AiEditAlert.all.group(:course_id, :article_id).having('count(*) > 1').count
same_page.each_key do |(courseid, articleid)|
  alerts = AiEditAlert.where(course_id: courseid, article_id: articleid)
  alerts.each_cons(2) do |first_alert, second_alert|
    second_alert.details[:prior_alert_for_page] = first_alert.id
    second_alert.save
  end
end
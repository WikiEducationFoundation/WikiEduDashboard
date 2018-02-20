json.count @course.articles_courses.live.includes(article: :wiki).count

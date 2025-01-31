# Data for the no-sandbox experiment


fall_2024 = Campaign.find_by_slug('fall_2024')

# articles edited, total edit count, mainspace edit count, mainspace bytes added, number of tickets, yes/no sandbox, new/returning, experiment_tag?, control tag?, how hard Q

headers = ['course', 'student count', 'articles edited', 'total edit count', 'mainspace edit count',
           'mainspace bytes added', 'ticket count', 'yes or no sandbox', 'new or returning',
           'experiment tag', 'how hard Q']
data = [headers]

fall_2024.courses.each do |c|
  puts c.slug
  row = []
  row << c.slug
  row << c.user_count
  row << c.article_count
  row << c.revisions.count
  row << c.revisions.joins(:article).where(articles: { namespace: Article::Namespaces::MAINSPACE, deleted: false }).count
  row << c.character_sum
  row << c.tickets.count
  row << (c.no_sandboxes? ? 'no sandboxes' : 'yes sandboxes')
  row << (c.returning_instructor? ? 'returning' : 'new')
  experiment_tag = if c.tag?('no_sandbox_fall_2024_experiment_condition')
                     'no_sandbox_fall_2024_experiment_condition'
                   elsif c.tag?('no_sandbox_fall_2024_control_condition')
                    'no_sandbox_fall_2024_control_condition'
                   end
  row << experiment_tag
  how_hard_answer = Rapidfire::AnswerGroup.find_by(course_id: c.id, question_group_id: 75)&.answers&.where(question_id: 1858)&.first&.answer_text
  row << how_hard_answer
  data << row
end

CSV.open("/home/sage/fall_2024_sandbox_data.csv", 'wb') do |csv|
  data.each { |line| csv << line }
end
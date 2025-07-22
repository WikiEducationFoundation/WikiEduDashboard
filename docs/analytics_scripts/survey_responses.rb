# Generate a list of people who responded with a specific answer to a survey question
QUESTION_ID = 1501
RESPONSE = "Presentations"

q = Rapidfire::Question.find(QUESTION_ID)
responses = q.answers.to_a.select { |a| a.answer_text&.include? RESPONSE }
people = responses.map { |a| "#{a.user.email}, #{a.user.username}, #{a.user.real_name}" }
puts people

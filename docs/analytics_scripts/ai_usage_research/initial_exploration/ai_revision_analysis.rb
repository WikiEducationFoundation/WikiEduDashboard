# Now we operate on the spreadsheet from csv_of_new_articles_by_term.rb,
# copied to development environment.

load 'docs/analytics_scripts/ai_usage_research/initial_exploration/rev_analyzer.rb'

articles_to_analyze = CSV.read 'new_articles_by_term_since_2022.csv'

headers = %w[title namespace mw_page_id deleted campaign course course_end_date first_student_editor
             redirect plain_text_length
             pangram_ai_likelihood
             pangram_avg_ai_likelihood
             pangram_max_ai_likelihood
             pangram_fraction_ai_content
             pangram_predicted_ai_window_count
             pangram_predicted_llm]
results = [headers]

i = 0
articles_to_analyze[1..].each do |row|
  i+= 1
  puts i
  result_row = row
  mw_page_id = row[2]
  course_end_date = row[6]
  analysis = RevAnalyzer.new(mw_page_id, course_end_date)
  analysis.analyze

  # TODO: add average gpt_zero sentence score
  # analysis.gpt_zero

  analysis.pangram

  result_row.concat [analysis.redirect, analysis.plain_text_length,
                     analysis.pangram_ai_likelihood,
                     analysis.pangram_average_ai_likelihood,
                     analysis.pangram_max_ai_likelihood,
                     analysis.pangram_fraction_ai_content,
                     analysis.pangram_predicted_ai_window_count,
                     analysis.pangram_predicted_llm]
  
  results << result_row
end

CSV.open("/home/sage/WikiEduDashboard/new_articles_by_term_since_2022_analyzed_part_4.csv", 'wb') do |csv|
  results.each { |line| csv << line }
end
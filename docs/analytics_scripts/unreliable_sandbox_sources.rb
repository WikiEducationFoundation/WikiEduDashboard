campaign = Campaign.find_by_slug 'fall_2021'

violations = [["course", "sandbox", "violation_comment", "first_match", "match_count"]]

campaign.courses.each do |course|
  puts course.slug
  violations += CheckSandboxes.new(course: course).check_sandboxes
end

File.write("/alloc/data/unreliable.csv", violations.map(&:to_csv).join)

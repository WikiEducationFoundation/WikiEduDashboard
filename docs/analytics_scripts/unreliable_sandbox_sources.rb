campaign = Campaign.find_by_slug 'fall_2021'

violations = []

campaign.courses.each do |course|
  violations += CheckSandboxes.new(course: course).check_sandboxes
end

File.write("/alloc/data/unreliable.csv", violations.map(&:to_csv).join)

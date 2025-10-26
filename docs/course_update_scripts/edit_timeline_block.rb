# frozen_string_literal: true

# This script updates the content of one of the standard timeline blocks

block_title = 'Continue improving your article'
# images training
new_training = 6
blocks = Block.where(title: block_title)

blocks.each do |block|
  block.training_module_ids = block.training_module_ids | [new_training]
  if block.content[-6..-1] == "</ul>\n"
    block.content[-6..-1] = "<li>Consider adding an image to your article. Wikipedia has strict rules about what media can be added, so make sure to take the 'Contributing Images and Media Files' training before you upload an image.</li>\n</ul>\n"
  end
  block.save
end

# This script adds a training module to a standard block on a set of courses

new_training = 68 # improving representation
block_title = 'Evaluate Wikipedia'

fall_2024 = Campaign.find_by_slug 'fall_2024'
ke_camp = Campaign.find_by_slug 'knowledge_equity'

fall_ke = fall_2024.courses.to_a & ke_camp.courses.to_a

fall_ke.each do |course|
  block = course.blocks.where(title: block_title).first
  next unless block
  next if block.training_module_ids.include? new_training
  block.training_module_ids << new_training
  block.save
  puts course.slug
end

# This script replaces the deprecated 'bibliography + outline' exercise
# with separate 'bibliography' and 'outline' exercises
# [38] => [72, 73]
ClassroomProgramCourse.where('start > ?', '2025-07-01'.to_date).each do |course|
  block = course.blocks.where(training_module_ids: [38]).first
  next unless block
  block.training_module_ids = [72,73]
  block.save
  puts course.slug
end

new_training = 71 # gen AI
block_title = 'Evaluate Wikipedia'

fall_2025 = Campaign.find_by_slug 'fall_2025'
missing = fall_2025.courses.select { |c| !c.training_module_ids.include? new_training }

missing.each do |course|
  block = course.blocks.where(title: block_title).first
  next unless block
  next if block.training_module_ids.include? new_training
  block.training_module_ids << new_training
  block.save
  puts course.slug
end

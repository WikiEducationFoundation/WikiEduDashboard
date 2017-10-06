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

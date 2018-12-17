# Replaces all relative links to training pages with absolute links, to
# avoid possible broken links depending on where block content is being shown.
bad_block_ids = Block.all.select { |b| b.content[/\.\.\/training/] }.map(&:id)

bad_block_ids.each do |block_id|
  block = Block.find block_id
  block.content.gsub! '"../../training', '"https://dashboard.wikiedu.org/training'
  block.content.gsub! '"../../../training', '"https://dashboard.wikiedu.org/training'
  block.save
end

# Fixes training links that lack the domain, so that TinyMCE won't turn them
# into relative links upon editing the block.
more_bad_block_ids = Block.all.select { |b| b.content[/"\/training/] }.map(&:id)

more_bad_block_ids.each do |block_id|
  block = Block.find block_id
  block.content.gsub! '"/training', '"https://dashboard.wikiedu.org/training'
  block.save
end

# Replaces links to training pages with asssigned modules

# evaluate-wikipedia-exercise #34
# On production, this fixed 1121 blocks on cloneable courses. All the blocks that included the exercise link were unmodified, so they had exactly this complete content.
# 81 additional blocks are in non-cloneable courses. Those have been left intact.
evaluate_exercise_blocks = Block.all.select { |b| b.content == "<h4 class=\"timeline-exercise\">Exercise</h4>\n<a href=\"https://dashboard.wikiedu.org/training/students/evaluate-wikipedia-exercise\" class=\"timeline-exercise\">Evaluate an article</a>\n" }
evaluate_exercise_blocks_to_fix = evaluate_exercise_blocks.select { |b| b.course.cloneable? }
evaluate_exercise_blocks_to_fix.each { |b| b.training_module_ids += [34]; b.content = nil; b.save }

# thinking-about-sources-and-plagiarism #43
# Not an exercise, so not strictly necessary.

# choose-topics-exercise #37
# 686 out of 732 were from cloneable courses.
choose_topics_blocks = Block.all.select { |b| b.content == "<h4 class=\"timeline-exercise\">Exercise</h4>\n<a href=\"https://dashboard.wikiedu.org/training/students/choose-topic-exercise\" class=\"timeline-exercise\">Choose a topic</a>\n\n<p>Resource: <a href=\"https://wikiedu.org/editingwikipedia#page=6\">Editing Wikipedia</a>, page 6</p>\n" }
choose_topics_blocks_to_fix = choose_topics_blocks.select { |b| b.course.cloneable? }
choose_topics_blocks_to_fix.each { |b| b.training_module_ids += [37]; b.content = "<p>Resource: <a href=\"https://wikiedu.org/editingwikipedia#page=6\">Editing Wikipedia</a>, page 6</p>\n"; b.save }

# add-to-article-exercise #35
# 1014 out of 1088 were from cloneable courses.
add_to_article_blocks = Block.all.select { |b| b.content == "<h4 class=\"timeline-exercise\">Exercise</h4>\n<a href=\"https://dashboard.wikiedu.org/training/students/add-to-article-exercise\" class=\"timeline-exercise\">Add a citation</a>\n" }
add_to_article_blocks_to_fix = add_to_article_blocks.select { |b| b.course.cloneable? }
add_to_article_blocks_to_fix.each { |b| b.training_module_ids += [35]; b.content = nil; b.save }

# copyedit-exercise #27
# 271 out of 290 were from cloneable courses.
copyedit_blocks = Block.all.select { |b| b.content == "<a href=\"https://dashboard.wikiedu.org/training/students/copyedit-exercise/copyedit-an-article\" class=\"timeline-exercise\">Copyedit an article</a>\n" }
copyedit_blocks_to_fix = copyedit_blocks.select { |b| b.course.cloneable? }
copyedit_blocks_to_fix.each { |b| b.training_module_ids += [27]; b.content = nil; b.save }

# finalize-topic-exercise #38
# 708 out of 753 were from cloneable courses.
finalize_topic_blocks = Block.all.select { |b| b.content == "<a href=\"https://dashboard.wikiedu.org/training/students/finalize-topic-exercise\" class=\"timeline-exercise\">Finalize your topic / Find your sources</a>\n" }
finalize_topic_blocks_to_fix = finalize_topic_blocks.select { |b| b.course.cloneable? }
finalize_topic_blocks_to_fix.each { |b| b.training_module_ids += [38]; b.content = nil; b.save }

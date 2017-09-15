require('ggplot2')
require('dplyr')

csv_path <- '/home/sage/play/ores-changes/spring_2017-articles-2017-09-14.csv'
# csv_path <- '/home/sage/play/ores-changes/visiting_scholars-articles-2017-09-15.csv'
campaign_data <- read.csv(csv_path)
campaign_data$ores_diff <- with(campaign_data, ores_after - ores_before)

# All articles
before <- select(campaign_data, select=('ores_before'))
after <- select(campaign_data, select=('ores_after'))
names(before)[1] = 'structural_completeness'
names(after)[1] = 'structural_completeness'
before$when <- 'before'
after$when <- 'after'
before_after_histogram <- rbind(before, after)

png(filename="before-after.png", width = 600, height = 400)
ggplot(before_after_histogram, aes(structural_completeness, fill=when)) + geom_density(alpha = 0.4, adjust = 1/2)
dev.off()

# major edits + diff
diff <- select(campaign_data, select=('ores_diff'))

major_edits <- campaign_data[campaign_data$bytes_added >= 6000, ]
# major_edits_existing <- major_edits
major_edits_existing <- major_edits[major_edits$ores_before > 0.0, ]
major_diff <- select(major_edits, select=('ores_diff'))

major_edits_existing_before <- select(major_edits_existing, select=('ores_before'))
major_edits_existing_after <- select(major_edits_existing, select=('ores_after'))

names(diff)[1] = 'change_in_structural_completeness'
names(major_diff)[1] = 'change_in_structural_completeness'
names(major_edits_existing_before)[1] = 'structural_completeness'
names(major_edits_existing_after)[1] = 'structural_completeness'

major_edits_existing_before$when <- 'before'
major_edits_existing_after$when <- 'after'

major_edits_existing_histogram <- rbind(major_edits_existing_before, major_edits_existing_after)
png(filename="before-after-major-edits.png", width = 600, height = 400)
ggplot(major_edits_existing_histogram, aes(structural_completeness, fill=when)) + geom_density(alpha = 0.4, adjust = 1/2)
dev.off()

# ggplot(diff, aes(change_in_structural_completeness)) + geom_density(alpha = 0.4, adjust = 1/2)
png(filename="major_articles_improvement.png", width = 600, height = 400)
ggplot(major_diff, aes(change_in_structural_completeness)) + geom_density(alpha = 0.4, adjust = 1/2)
dev.off()

# New articles
new_articles <- campaign_data[campaign_data$ores_before == 0.0, ]
new_articles <- new_articles[new_articles$bytes_added >= 2000, ]
new_articles_after <- select(new_articles, select=('ores_after'))
names(new_articles_after)[1] = 'structural_completeness'
new_articles_after$when <- 'after'

png(filename="new-articles.png", width = 600, height = 400)
ggplot(new_articles_after, aes(structural_completeness, fill=when)) + geom_density(alpha = 0.4, adjust = 1/2)
dev.off()

# Existing articles
existing_articles <- campaign_data[campaign_data$ores_before > 0.0, ]
existing_articles_before <- select(existing_articles, select=('ores_before'))
existing_articles_after <- select(existing_articles, select=('ores_after'))

names(existing_articles_before)[1] = 'structural_completeness'
names(existing_articles_after)[1] = 'structural_completeness'
existing_articles_before$when = 'before'
existing_articles_after$when = 'after'

existing_articles_histogram <- rbind(existing_articles_before, existing_articles_after)
png(filename="existing-before-after.png", width = 600, height = 400)
ggplot(before_after_histogram, aes(structural_completeness, fill=when)) + geom_density(alpha = 0.4, adjust = 1/2)
dev.off()

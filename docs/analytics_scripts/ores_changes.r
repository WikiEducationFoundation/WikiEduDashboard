require('ggplot2')
require('dplyr')

term <- 'visiting_scholars'
date <- '2017-09-15'
csv_path <- paste('/home/sage/play/ores-changes/', term, '-articles-', date, '.csv', sep='')
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

before_after_file <- paste(term, "-before-after.png", sep='')
png(filename=before_after_file, width = 600, height = 400)
ggplot(before_after_histogram, aes(structural_completeness, fill=when)) + geom_density(alpha = 0.4, adjust = 1/2)
dev.off()


# major edits 1000

major_edits_1000 <- campaign_data[campaign_data$bytes_added >= 1000, ]
# major_edits_existing <- major_edits
major_edits_existing_1000 <- major_edits_1000[major_edits_1000$ores_before > 0.0, ]

major_edits_existing_1000_before <- select(major_edits_existing_1000, select=('ores_before'))
major_edits_existing_1000_after <- select(major_edits_existing_1000, select=('ores_after'))

names(major_edits_existing_1000_before)[1] = 'structural_completeness'
names(major_edits_existing_1000_after)[1] = 'structural_completeness'

major_edits_existing_1000_before$when <- 'before'
major_edits_existing_1000_after$when <- 'after'

major_edits_existing_1000_histogram <- rbind(major_edits_existing_1000_before, major_edits_existing_1000_after)
before_after_major_1000_filename <- paste(term, "-before-after-major-edits-1000.png", sep='')
png(filename=before_after_major_1000_filename, width = 1200, height = 800)
ggplot(major_edits_existing_1000_histogram, aes(structural_completeness, fill=when)) +
  geom_density(alpha = 0.4, adjust = 1/2) +
  xlab('Structural Completeness (based on ORES wp10 model)') +
  theme(legend.background = element_rect(colour = "white"),
        legend.position = c(.8, .85),
        axis.title=element_text(size=26,face="bold"),
        legend.text=element_text(size=40)) +
  guides(fill=guide_legend(title=""))
# ggplot(major_edits_existing_1000_histogram, aes(structural_completeness, fill=when)) + geom_density(alpha = 0.4, adjust = 1/2)
dev.off()

# major edits 6000
major_edits_6000 <- campaign_data[campaign_data$bytes_added >= 6000, ]
# major_edits_existing <- major_edits
major_edits_existing_6000 <- major_edits_6000[major_edits_6000$ores_before > 0.0, ]

major_edits_existing_6000_before <- select(major_edits_existing_6000, select=('ores_before'))
major_edits_existing_6000_after <- select(major_edits_existing_6000, select=('ores_after'))


names(major_edits_existing_6000_before)[1] = 'structural_completeness'
names(major_edits_existing_6000_after)[1] = 'structural_completeness'

major_edits_existing_6000_before$when <- 'before'
major_edits_existing_6000_after$when <- 'after'

major_edits_existing_6000_histogram <- rbind(major_edits_existing_6000_before, major_edits_existing_6000_after)
before_after_major_6000_filename <- paste(term, "-before-after-major-edits-6000.png", sep='')
png(filename=before_after_major_6000_filename, width = 600, height = 400)
ggplot(major_edits_existing_6000_histogram, aes(structural_completeness, fill=when)) + geom_density(alpha = 0.4, adjust = 1/2)
dev.off()



# diff <- select(campaign_data, select=('ores_diff'))
# names(diff)[1] = 'change_in_structural_completeness'
# major_diff_6000 <- select(major_edits_6000, select=('ores_diff'))
# names(major_diff_6000)[1] = 'change_in_structural_completeness'

# major_improvement_filename <- paste(term, "major_articles_improvement.png", sep='')
# png(filename=major_improvement_filename, width = 600, height = 400)
# ggplot(major_diff, aes(change_in_structural_completeness)) + geom_density(alpha = 0.4, adjust = 1/2)
# dev.off()

# New articles
new_articles <- campaign_data[campaign_data$ores_before == 0.0, ]
new_articles_after <- select(new_articles, select=('ores_after'))
names(new_articles_after)[1] = 'structural_completeness'
new_articles_after$when <- 'after'

new_articles_filename <- paste(term, "-new-articles.png", sep='')
png(filename=new_articles_filename, width = 600, height = 400)
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
existing_articles_filename <- paste(term, "-existing-before-after.png", sep='')
png(filename=existing_articles_filename, width = 600, height = 400)
ggplot(before_after_histogram, aes(structural_completeness, fill=when)) + geom_density(alpha = 0.4, adjust = 1/2)
dev.off()

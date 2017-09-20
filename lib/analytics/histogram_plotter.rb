require 'rinruby'

require "#{Rails.root}/lib/analytics/campaign_articles_csv_builder"

class HistogramPlotter
  def initialize(campaign:)
    @campaign = campaign
    build_csv
    initialize_r
    load_dataframe
  end

  def major_edits_plot(minimum_bytes: 1000)
    @minimum_bytes = minimum_bytes
    filter_by_bytes_added minimum_bytes
    prepare_histogram_data
    plot_histogram
    return public_plot_path
  end

  private

  def build_csv
    Dir.mkdir(analytics_path) unless File.exists?(analytics_path)
    csv_content = CampaignArticlesCsvBuilder.new(@campaign).articles_to_csv
    File.write(csv_path, csv_content)
  end

  def csv_path
    "#{analytics_path}/#{@campaign.slug}.csv"
  end

  def plot_path
    "#{analytics_path}/#{plot_filename}"
  end

  def public_plot_path
    "assets/images/analytics/#{plot_filename}"
  end

  def assets_directory
    'public/assets/images'
  end

  def analytics_path
    "#{assets_directory}/analytics"
  end

  def plot_filename
    "#{@campaign.slug}-ores-#{@minimum_bytes}.png"
  end

  def initialize_r
    R.eval "require('ggplot2')"
    R.eval "require('dplyr')"
  end

  def load_dataframe
    R.eval "campaign_data <- read.csv('#{csv_path}')"
    R.eval "campaign_data$ores_diff <- with(campaign_data, ores_after - ores_before)"
    R.eval "histogram_data <- campaign_data"
  end

  def filter_by_bytes_added(minimum_bytes)
    R.eval "histogram_data <- campaign_data[campaign_data$bytes_added >= #{minimum_bytes}, ]"
  end

  def prepare_histogram_data
    R.eval "before <- select(histogram_data, select=('ores_before'))"
    R.eval "after <- select(histogram_data, select=('ores_after'))"
    R.eval "names(before)[1] = 'structural_completeness'"
    R.eval "names(after)[1] = 'structural_completeness'"
    R.eval "before$when <- 'before'"
    R.eval "after$when <- 'after'"
    R.eval "histogram <- rbind(before, after)"
  end

  def plot_histogram
    R.eval "png(filename='#{plot_path}', width = 1200, height = 800)"
    R.eval <<-PLOT
      ggplot(histogram, aes(structural_completeness, fill=when)) +
        geom_density(alpha = 0.4, adjust = 1/2) +
        xlab('Structural Completeness (based on ORES wp10 model)') +
        theme(legend.background = element_rect(colour = "white"),
              legend.position = c(.8, .85),
              axis.title=element_text(size=26,face="bold"),
              legend.text=element_text(size=40)) +
        guides(fill=guide_legend(title=""))
    PLOT
    R.eval "dev.off()"
  end
end

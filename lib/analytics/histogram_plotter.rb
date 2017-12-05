# frozen_string_literal: true

require 'rinruby'

require "#{Rails.root}/lib/analytics/ores_diff_csv_builder"

class HistogramPlotter
  def self.plot(campaign: nil, course: nil, opts: {})
    new(campaign: campaign, course: course).major_edits_plot(opts)
  rescue NoDataError => e
    return nil
  end

  def initialize(campaign: nil, course: nil, csv: nil)
    @campaign_or_course = campaign || course
    @csv = csv || csv_path
    build_csv unless csv
    initialize_r
    load_dataframe
  end

  def major_edits_plot(minimum_bytes: 0, existing_only: false, type: 'density',
                       minimum_improvement: nil, simple: false)
    @minimum_bytes = minimum_bytes
    @existing_only = existing_only
    @minimum_improvement = minimum_improvement
    @simple = simple

    filter_by_bytes_added
    filter_out_new_articles if existing_only
    filter_by_improvement if minimum_improvement
    prepare_histogram_data

    case type
    when 'histogram'
      plot_histogram
    when 'density'
      plot_density
    end

    return public_plot_path
  end

  private

  def build_csv
    FileUtils.mkdir_p analytics_path
    return if File.exist? csv_path
    courses = @campaign_or_course.is_a?(Course) ? [@campaign_or_course] : @campaign_or_course.courses
    csv_content = OresDiffCsvBuilder.new(courses).articles_to_csv
    File.write(csv_path, csv_content)
  end

  def slug_filename
    return if @campaign_or_course.nil?
    # Create a version that is safe as a path and does not have quote characters
    @campaign_or_course.slug.tr('/', '—').tr("'", '-')
  end

  def csv_path
    "#{analytics_path}/#{slug_filename}-#{Date.today}.csv"
  end

  def plot_path
    "#{analytics_path}/#{plot_filename}"
  end

  def public_plot_path
    "#{public_analytics_path}/#{plot_filename}"
  end

  def public_analytics_path
    'assets/system/analytics'
  end

  def analytics_path
    "public/#{public_analytics_path}"
  end

  def plot_filename
    "#{slug_filename}-ores-#{@minimum_bytes}.png"
  end

  def plot_title
    return '' if @simple
    "#{slug_filename} before & after, #{Date.today} #{@existing_only ? '(existing articles only)' : '(new and existing articles)'}"
  end

  def plot_subtitle
    R.eval "before_count <- nrow(subset(histogram, when=='before'))"
    R.eval "before_mean <- mean(subset(histogram, when=='before')$structural_completeness)"
    R.eval "after_mean <- mean(subset(histogram, when=='after')$structural_completeness)"

    average_before_after = "ave. before: #{R.before_mean.round(1)} - ave. after: #{R.after_mean.round(1)}"
    return average_before_after if @simple

    improvement_limit = @minimum_improvement ? "min improvement: #{@minimum_improvement} - " : ''
    "#{improvement_limit}min bytes added: #{@minimum_bytes} - articles: #{R.before_count} - #{average_before_after}"
  end

  def initialize_r
    R.eval "require('ggplot2')"
    R.eval "require('dplyr')"
  end

  def load_dataframe
    # If the file has no data beyond the header, the R code will break.
    raise NoDataError unless File.read(@csv).each_line.count > 1

    R.eval "campaign_data <- read.csv('#{@csv}')"
    R.eval 'campaign_data$ores_diff <- with(campaign_data, ores_after - ores_before)'
    R.eval 'histogram_data <- campaign_data'
  end

  def filter_by_bytes_added
    R.eval "histogram_data <- campaign_data[campaign_data$bytes_added >= #{@minimum_bytes}, ]"
  end

  def filter_out_new_articles
    R.eval 'histogram_data <- histogram_data[histogram_data$ores_before > 0.0, ]'
  end

  def filter_by_improvement
    R.eval "histogram_data <- histogram_data[histogram_data$ores_diff >= #{@minimum_improvement}, ]"
  end

  def prepare_histogram_data
    R.eval 'before <- select(histogram_data, ores_before)'
    R.eval 'after <- select(histogram_data, ores_after)'
    R.eval "names(before)[1] = 'structural_completeness'"
    R.eval "names(after)[1] = 'structural_completeness'"
    R.eval "before$when <- 'before'"
    R.eval "after$when <- 'after'"
    R.eval 'histogram <- rbind(before, after)'
  end

  def plot_density
    R.eval "png(filename='#{plot_path}', width = 1200, height = 800)"
    R.eval <<-PLOT
      ggplot(histogram, aes(structural_completeness, fill=when)) +
        scale_fill_manual(values=c("#676eb4", "#359178")) +
        geom_density(aes(y = ..count..), alpha = 0.4, adjust = 1/2) +
        xlab('Structural Completeness') +
        theme(legend.background = element_rect(colour = "white"),
              legend.position = c(.8, .85),
              axis.title=element_text(size=26,face="bold"),
              plot.title=element_text(face='bold', size=28, hjust = 0.5),
              plot.subtitle=element_text(size=22, hjust = 0.5),
              legend.text=element_text(size=40)) +
        guides(fill=guide_legend(title="")) +
        labs(title='#{plot_title}', subtitle='#{plot_subtitle}')
    PLOT
    R.eval 'dev.off()'
  end

  # Alternative colors: scale_fill_manual(values=c("#676eb4", "#359178")) +
  def plot_histogram
    R.eval "png(filename='#{plot_path}', width = 1200, height = 800)"
    R.eval <<-PLOT
      ggplot(histogram, aes(structural_completeness, fill=when)) +
        geom_histogram(data=subset(histogram, when='before'), aes(y = ..count..), alpha = 0.3, position="identity", binwidth=2) +
        geom_histogram(data=subset(histogram, when='after'), aes(y = ..count..), alpha = 0.3, position="identity", binwidth=2) +
        xlab('Structural Completeness (based on ORES wp10 model)') +
        theme(legend.background = element_rect(colour = "white"),
              legend.position = c(.8, .85),
              axis.title=element_text(size=26,face="bold"),
              plot.title=element_text(face='bold', size=28, hjust = 0.5),
              plot.subtitle=element_text(size=22, hjust = 0.5),
              legend.text=element_text(size=40)) +
        guides(fill=guide_legend(title="")) +
        labs(title='#{plot_title}', subtitle='#{plot_subtitle}')
    PLOT
    R.eval 'dev.off()'
  end

  class NoDataError < StandardError; end
end

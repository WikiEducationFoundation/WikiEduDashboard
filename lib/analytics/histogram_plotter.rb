# frozen_string_literal: true

require_dependency "#{Rails.root}/lib/analytics/ores_diff_csv_builder"

class HistogramPlotter
  def self.csv(course: nil, campaign: nil)
    new(course: course, campaign: campaign).csv_path
  end

  def initialize(campaign: nil, course: nil, csv: nil)
    @campaign_or_course = campaign || course
    @csv = csv || csv_path
    build_csv unless csv
  end

  def csv_path
    "#{analytics_path}/#{csv_filename}"
  end

  private

  def build_csv
    FileUtils.mkdir_p analytics_path
    return if File.exist? csv_path
    courses =
      @campaign_or_course.is_a?(Course) ? [@campaign_or_course] : @campaign_or_course.courses
    csv_content = OresDiffCsvBuilder.new(courses).articles_to_csv
    File.write(csv_path, csv_content)
  end

  def slug_filename
    return if @campaign_or_course.nil?
    # Create a version that is safe as a path and does not have quote characters
    @campaign_or_course.slug.tr('/', '—').tr("'", '-')
  end

  def csv_filename
    "#{slug_filename}-#{Date.today}.csv"
  end

  def public_analytics_path
    'assets/system/analytics'
  end

  def analytics_path
    "public/#{public_analytics_path}"
  end
end

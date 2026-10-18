# frozen_string_literal: true

require_dependency "#{Rails.root}/app/services/summarize_detector_comparison"
require_dependency "#{Rails.root}/app/services/summarize_known_human_texts"
require_dependency "#{Rails.root}/app/services/describe_detector_comparison_unit"

# Writes the data behind the detector comparison page to files, which the page
# serves as they are: each dataset, every unit either dataset lists, and a
# manifest with the publication time and the size of each dataset. Building the
# data parses every stored score, so it is done here once rather than on
# requests, and the page changes only when this runs: run it from the console
# after a scoring round. Each publication is a new directory under the root,
# and `current` points to it once every file is written; older ones beyond
# KEEP are removed. Every file is written plain and gzipped.
class PublishDetectorComparison
  DIRNAME = 'detector_comparison_snapshots'
  CURRENT = 'current'
  MANIFEST = 'manifest'
  KEEP = 3
  SNAPSHOT_NAME = /\A\d{8}-\d{9}\z/

  attr_reader :path, :counts

  def self.root
    Rails.root.join(DIRNAME)
  end

  # A file of the current publication, or nil when it has none.
  def self.published_file(name)
    file = root.join(CURRENT, "#{name}.json")
    file if file.file?
  end

  def self.manifest
    file = published_file(MANIFEST)
    file && JSON.parse(file.read)
  end

  def initialize
    @root = self.class.root
    @path = @root.join(Time.zone.now.utc.strftime('%Y%m%d-%H%M%S%L'))
    publish
  end

  private

  def publish
    topics = SummarizeDetectorComparison.new.result
    known_human = SummarizeKnownHumanTexts.new.result
    write('topics', topics)
    write('known_human', known_human)
    write_units(topics, known_human)
    @counts = { topics: topics[:units].size, known_human: known_human[:units].size }
    write(MANIFEST, { published_at: Time.zone.now, counts: @counts })
    point_current_here
    remove_old
  end

  def write_units(topics, known_human)
    ids = (topics[:units] + known_human[:units]).map { |unit| unit[:id] }.uniq
    ids.each do |id|
      write("units/#{id}", DescribeDetectorComparisonUnit.new(id, topics:, known_human:).result)
    end
  end

  def write(name, data)
    json = data.to_json
    file = @path.join("#{name}.json")
    FileUtils.mkdir_p(file.dirname)
    File.write(file, json)
    File.binwrite("#{file}.gz", ActiveSupport::Gzip.compress(json))
  end

  # Renaming a new link over the old one switches every file at once. The link is relative,
  # so it holds wherever the root is mounted.
  def point_current_here
    link = @root.join("#{CURRENT}.#{SecureRandom.hex(4)}")
    File.symlink(@path.basename, link)
    File.rename(link, @root.join(CURRENT))
  end

  def remove_old
    snapshots = @root.children.select { |child| child.basename.to_s.match?(SNAPSHOT_NAME) }
    snapshots.sort.reverse.drop(KEEP).each { |snapshot| FileUtils.rm_rf(snapshot) }
  end
end

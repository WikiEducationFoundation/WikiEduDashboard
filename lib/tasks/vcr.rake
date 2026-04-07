# frozen_string_literal: true

namespace :vcr do
  CASSETTE_DIR = 'fixtures/vcr_cassettes'
  CACHED_DIR   = "#{CASSETTE_DIR}/cached"

  desc 'Clear local (non-committed) VCR cassettes'
  task :clear do
    removed = clear_cassettes(CASSETTE_DIR, exclude: CACHED_DIR)
    puts "Removed #{removed} cassette(s)."
  end

  desc 'Clear cassettes under a path or matching a name prefix ' \
       '(e.g. rake vcr:clear_path[liftwing_api] or rake vcr:clear_path[course_revision_updater])'
  task :clear_path, [:path] do |_, args|
    path = args[:path] || raise(ArgumentError, 'Usage: rake vcr:clear_path[path]')
    target = "#{CASSETTE_DIR}/#{path}"
    files = if File.directory?(target)
              Dir.glob("#{target}/**/*").select { |f| File.file?(f) }
            else
              Dir.glob("#{target}*").select { |f| File.file?(f) }
            end
    files.each { |f| File.delete(f) }
    puts "Removed #{files.size} cassette(s)."
  end

  def clear_cassettes(dir, exclude: nil)
    files = Dir.glob("#{dir}/**/*").select { |f| File.file?(f) }
    files.reject! { |f| f.start_with?(exclude) } if exclude
    files.each { |f| File.delete(f) }
    files.size
  end
end

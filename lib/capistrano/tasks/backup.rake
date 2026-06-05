# frozen_string_literal: true

# Uses system ssh/scp (not Capistrano roles) so that ~/.ssh/config
# ProxyJump, aliases, etc. work and no Ruby is needed on the remote.

def ssh_capture(host, cmd)
  `ssh #{host} #{Shellwords.escape(cmd)}`.strip
end

def fetch_backup_info(host, path)
  cmd = "ls -lh #{path}/*/dashboard-dump-*.sql.gz 2>/dev/null; " \
        "echo '---'; df -h #{path}"
  raw = ssh_capture(host, cmd)
  listing, df = raw.split('---', 2).map(&:strip)
  files = listing.split("\n").map(&:strip).sort
  [files, df]
end

namespace :backup do
  desc 'Download the latest database backup from the server'
  task :download do
    host = fetch(:backup_host)
    path = fetch(:backup_path)

    lines, df = fetch_backup_info(host, path)
    if lines.empty?
      warn "No backups found in #{path} on #{host}"
      exit 1
    end

    puts "=== Backups on #{host} (#{path}) ==="
    lines.each { |l| puts "  #{l}" }
    puts "\n#{df}"

    latest = lines.last.split.last
    filename = File.basename(latest)
    local_dir = File.join('backups', fetch(:stage).to_s)
    FileUtils.mkdir_p(local_dir)
    local_path = File.join(local_dir, filename)

    puts "\nDownloading #{filename} → #{local_path} ..."
    system('scp', "#{host}:#{latest}", local_path)

    mb = (File.size(local_path) / 1024.0 / 1024).round(1)
    puts "Done — saved #{mb} MB to #{local_path}"
  end
end

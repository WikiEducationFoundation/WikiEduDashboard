# frozen_string_literal: true

require 'open3'

# Builds a `git format-patch` email for one commit that changes the given
# files, ready for `git am`. Git does the diffing in a throwaway repository, so
# the patch carries full blob ids and `git am -3` can merge it into a checkout
# where those files have changed since.
#
# Paths are relative to the repository root. In changed_files, a nil value
# deletes the file.
class BuildGitPatch
  attr_reader :patch

  def initialize(base_files:, changed_files:, message:, author_name:, author_email:)
    @base_files = base_files
    @changed_files = changed_files
    @message = message
    @author = { name: author_name.to_s, email: author_email.to_s }
    Dir.mktmpdir('build-git-patch') do |dir|
      @dir = Pathname.new(dir)
      perform
    end
  end

  private

  def perform
    git('init', '--quiet')
    write_files(@base_files)
    base = commit('Base')
    write_files(@changed_files)
    update = commit(@message, parent: base)
    @patch = git('format-patch', '--stdout', '--full-index', '--find-renames',
                 '--no-signature', '-1', update)
  end

  def commit(message, parent: nil)
    git('add', '--all')
    tree = git('write-tree').strip
    parent_args = parent ? ['-p', parent] : []
    git('commit-tree', tree, *parent_args, '-m', message).strip
  end

  def write_files(files)
    files.each do |path, text|
      full_path = path_in_repo(path)
      if text.nil?
        FileUtils.rm_f(full_path)
      else
        FileUtils.mkdir_p(full_path.dirname)
        full_path.write(text)
      end
    end
  end

  def path_in_repo(path)
    full_path = @dir.join(path).cleanpath
    unless Pathname.new(path).relative? && full_path.to_s.start_with?("#{@dir}/")
      raise ArgumentError, "Path #{path.inspect} is outside the repository"
    end
    full_path
  end

  def git(*args)
    output, error, status = Open3.capture3(git_env, 'git', '-C', @dir.to_s, *args)
    raise GitError, "git #{args.first} failed: #{error}" unless status.success?
    output
  end

  # Ignore the server's own git config and environment, which could change the
  # diff format (diff.noprefix, color) or point git at another repository.
  def git_env
    {
      'GIT_CONFIG_GLOBAL' => File::NULL, 'GIT_CONFIG_NOSYSTEM' => '1',
      'GIT_DIR' => nil, 'GIT_WORK_TREE' => nil, 'GIT_INDEX_FILE' => nil,
      'GIT_AUTHOR_NAME' => @author[:name], 'GIT_AUTHOR_EMAIL' => @author[:email],
      'GIT_COMMITTER_NAME' => @author[:name], 'GIT_COMMITTER_EMAIL' => @author[:email]
    }
  end

  class GitError < StandardError; end
end

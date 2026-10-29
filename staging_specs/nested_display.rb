# frozen_string_literal: true

# Runs the visible staging browser inside a nested Xephyr X server, so the
# browser's window raises and focus grabs land on that display instead of the
# operator's real desktop. They can keep working elsewhere while a run churns,
# watch it in the nested window, and click into it only to clear a login
# challenge.
#
# On by default for headed runs. Skipped under HEADLESS (no window at all), with
# XEPHYR=0, when Xephyr isn't installed, and when a parent process already
# started one: bin/harvest-canvas-screenshots opens one window for its whole run,
# and each bin/staging-feature-spec it shells out to reuses it.
#
# Not loaded by staging_specs/spec_helper.rb; only the bin/ runners use it.
module NestedDisplay
  # The browser window size lives in staging_specs/spec_helper.rb (1280x900);
  # the nested screen must exceed it.
  SCREEN = '1440x960'
  # Set to the nested display while one is up, so child runners reuse it.
  ACTIVE_ENV = 'STAGING_NESTED_DISPLAY'

  module_function

  # Whether a run started now would land on a nested display, either one this
  # process would start or one a parent already started.
  def nested?
    active? || (wanted? && xephyr_installed?)
  end

  # Yields with DISPLAY pointed at a fresh nested display (or unchanged, when
  # nesting doesn't apply) and returns the block's value.
  def wrap
    return yield unless wanted?
    unless xephyr_installed?
      warn '  [xephyr] Xephyr not on PATH; running on the normal display.'
      return yield
    end

    display = free_display
    pid = spawn('Xephyr', display, '-screen', SCREEN, '-resizeable', '-no-host-grab',
                '-title', 'staging specs', out: File::NULL, err: File::NULL)
    wait_for_x_socket(display)
    ENV['DISPLAY'] = ENV[ACTIVE_ENV] = display
    warn "  [xephyr] the browser runs in a nested window on #{display}; focus stays " \
         'there. Click into it only to clear a login challenge. XEPHYR=0 opts out.'
    yield
  ensure
    if pid
      terminate(pid)
      ENV.delete(ACTIVE_ENV)
    end
  end

  def active?
    !ENV[ACTIVE_ENV].to_s.empty?
  end

  def wanted?
    ENV['HEADLESS'].to_s.empty? && ENV['XEPHYR'] != '0' && !active?
  end

  def xephyr_installed?
    system('which', 'Xephyr', out: File::NULL, err: File::NULL)
  end

  # Lowest display number with no socket in /tmp/.X11-unix yet.
  def free_display
    taken = Dir.glob('/tmp/.X11-unix/X*').map { |s| File.basename(s)[1..].to_i }
    n = (1..99).find { |i| !taken.include?(i) } || abort('no free X display')
    ":#{n}"
  end

  def wait_for_x_socket(display, timeout: 10)
    socket = "/tmp/.X11-unix/X#{display[1..]}"
    deadline = Time.now + timeout
    sleep 0.1 until File.exist?(socket) || Time.now > deadline
    abort "Xephyr #{display} did not start" unless File.exist?(socket)
  end

  def terminate(pid)
    Process.kill('TERM', pid)
    Process.wait(pid)
  rescue Errno::ESRCH, Errno::ECHILD
    nil # already gone
  end
end

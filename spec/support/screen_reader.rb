# frozen_string_literal: true

require 'cgi'
require 'open3'

# Screen reader specs: examples tagged `:screen_reader` run in Chrome with Orca
# listening, and can move Orca around the page and check what it says.
#
#   it 'announces the highlighted run', :screen_reader do
#     visit ...
#     move_screen_reader_to('.parsed-article p')
#     expect(screen_reader_say_all).to include('Edited by Ragesoss')
#   end
#
# They run only under bin/screen-reader-spec, which starts Orca and sets
# ORCA_DEBUG_LOG; every other run leaves them out.
#
# What Orca says is read from its debug log: each utterance it hands to
# speech-dispatcher, in order. Helpers return those utterances as an array of
# strings, roles and states included ("link", "heading 1", "leaving panel.").
module ScreenReaderHelpers
  ORCA_SERVICE = 'org.gnome.Orca1.Service'
  # Speech goes to speech-dispatcher as a plain string followed by its own SSML
  # echo, or (during Say All) as SSML alone.
  SPEECH_LINE = /SPEECH DISPATCHER: Speaking '(.*)'( as string)?\s*$/
  QUIET_SECONDS = 0.6

  def screen_reader_next_line
    screen_reader_command('CaretNavigator', 'NextLine')
  end

  def screen_reader_next_word
    screen_reader_command('CaretNavigator', 'NextWord')
  end

  # Reads from the current position to the end of the page.
  def screen_reader_say_all
    screen_reader_command('SayAllPresenter', 'SayAll', until_logged: 'Stopped Say All', limit: 90)
  end

  # Puts the screen reader's reading position at the start of the first element
  # matching `selector`, the way a user's caret would land there.
  def move_screen_reader_to(selector)
    # Orca ignores caret moves that follow its own navigation commands until some
    # other input arrives; a bare Shift press is that input.
    system('xdotool', 'key', 'shift', exception: true)
    offset = File.size(orca_log)
    # Collapsing the selection to where it already is fires no event, so it goes
    # via the top of the page.
    page.execute_script(<<~JS, selector)
      document.activeElement.blur();
      const selection = window.getSelection();
      selection.collapse(document.body, 0);
      setTimeout(() => selection.collapse(document.querySelector(arguments[0]), 0), 300);
    JS
    sleep 0.4
    screen_reader_speech_since(offset)
  end

  # Runs one of Orca's D-Bus commands and returns what Orca said in response.
  def screen_reader_command(orca_module, command, until_logged: nil, limit: 10)
    offset = File.size(orca_log)
    output, status = Open3.capture2e(
      'gdbus', 'call', '--session', '-d', ORCA_SERVICE,
      '-o', "/org/gnome/Orca1/Service/#{orca_module}",
      '-m', "org.gnome.Orca1.#{orca_module}.#{command}", 'true'
    )
    raise "Orca #{orca_module}.#{command} failed: #{output}" unless status.success?
    screen_reader_speech_since(offset, until_logged:, limit:)
  end

  # Waits until the log has been quiet for a moment (or, given `until_logged`, until
  # that text appears), then returns the utterances logged after `offset`.
  def screen_reader_speech_since(offset, until_logged: nil, limit: 10)
    deadline = Time.zone.now + limit
    size = File.size(orca_log)
    changed_at = Time.zone.now
    while Time.zone.now < deadline
      break if until_logged ? orca_log_since(offset).include?(until_logged) : quiet?(changed_at)
      if File.size(orca_log) != size
        size = File.size(orca_log)
        changed_at = Time.zone.now
      end
      sleep 0.1
    end
    utterances(orca_log_since(offset))
  end

  private

  def orca_log
    ENV.fetch('ORCA_DEBUG_LOG')
  end

  def orca_log_since(offset)
    File.binread(orca_log)[offset..].force_encoding('UTF-8').scrub
  end

  def quiet?(changed_at)
    Time.zone.now - changed_at > QUIET_SECONDS
  end

  def utterances(log)
    spoken = []
    plain_text = nil
    log.scan(SPEECH_LINE).each do |logged, as_string|
      text = as_string ? logged : CGI.unescapeHTML(logged.gsub(/<[^>]+>/, ''))
      # Skip the SSML echo of the plain string just before it.
      spoken << text if as_string || plain_text&.strip != text.strip
      plain_text = as_string ? text : nil
    end
    spoken
  end
end

Capybara.register_driver :screen_reader do |app|
  # --force-renderer-accessibility exposes the page to Orca from the start;
  # --password-store=basic keeps a keyring prompt from taking focus.
  args = %w[no-sandbox disable-gpu --window-size=1200,1200 --lang=en
            --force-renderer-accessibility --password-store=basic]
  options = Selenium::WebDriver::Chrome::Options.new(args:)
  options.add_preference('intl.accept_languages', 'en-US,en')
  Capybara::Selenium::Driver.new(app, browser: :chrome, options:)
end

RSpec.configure do |config|
  config.filter_run_excluding :screen_reader unless ENV['ORCA_DEBUG_LOG']
  config.include ScreenReaderHelpers, :screen_reader
  config.before(:each, :screen_reader) { Capybara.current_driver = :screen_reader }
end

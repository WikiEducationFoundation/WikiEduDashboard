# frozen_string_literal: true

# When SLOW is set, add a configurable pause after each Capybara user interaction
# so that headed runs are easy to follow visually.
#
# Usage:
#   HEADED=1 SLOW=1 bin/feature-spec spec/features/foo_spec.rb
#
# SLOW value is the pause duration in seconds (decimals OK). Defaults to 1.
if ENV['SLOW']
  SLOW_DELAY = [ENV['SLOW'].to_f, 0.05].max

  slow_actions = Module.new do
    %i[click_link click_button click_link_or_button click_on
       fill_in check uncheck choose select].each do |m|
      define_method(m) do |*args, **kwargs, &block|
        result = super(*args, **kwargs, &block)
        sleep SLOW_DELAY
        result
      end
    end
  end
  Capybara::Node::Actions.prepend(slow_actions)

  slow_clicks = Module.new do
    %i[click double_click right_click].each do |m|
      define_method(m) do |*args, **kwargs, &block|
        result = super(*args, **kwargs, &block)
        sleep SLOW_DELAY
        result
      end
    end
  end
  Capybara::Node::Element.prepend(slow_clicks)

  slow_visit = Module.new do
    def visit(*args, **kwargs, &block)
      result = super
      sleep SLOW_DELAY
      result
    end
  end
  Capybara::Session.prepend(slow_visit)
end

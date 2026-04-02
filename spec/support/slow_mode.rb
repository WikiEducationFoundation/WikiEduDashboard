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
      inject_spec_label
      sleep SLOW_DELAY
      result
    end

    private

    def inject_spec_label
      example = RSpec.current_example
      return unless example

      description = example.description
      context_path = example.full_description
                            .sub(/\s*#{Regexp.escape(description)}\z/, '')
                            .strip
      execute_script(<<~JS)
        (function() {
          var el = document.getElementById('__rspec_label__');
          if (!el) {
            el = document.createElement('div');
            el.id = '__rspec_label__';
            el.style.cssText = [
              'position:fixed', 'bottom:0', 'left:0', 'right:0',
              'background:rgba(20,20,20,0.9)', 'color:#fff',
              'padding:6px 12px', 'font-family:monospace',
              'z-index:2147483647', 'pointer-events:none', 'line-height:1.4'
            ].join(';');
            var ctx = document.createElement('div');
            ctx.id = '__rspec_label_ctx__';
            ctx.style.cssText = 'font-size:11px;color:#aaa;margin-bottom:2px;';
            var desc = document.createElement('div');
            desc.id = '__rspec_label_desc__';
            desc.style.cssText = 'font-size:14px;font-weight:bold;color:#fff;';
            el.appendChild(ctx);
            el.appendChild(desc);
            document.body.appendChild(el);
          }
          document.getElementById('__rspec_label_ctx__').textContent = #{context_path.to_json};
          document.getElementById('__rspec_label_desc__').textContent = #{description.to_json};
        })();
      JS
    rescue StandardError
      nil # ignore injection errors (e.g. page not fully loaded)
    end
  end
  Capybara::Session.prepend(slow_visit)
end

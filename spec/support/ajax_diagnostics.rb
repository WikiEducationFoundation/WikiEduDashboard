# frozen_string_literal: true

# AJAX Diagnostics — tracks in-flight fetch/XHR requests at spec boundaries.
# Activate with AJAX_DIAG=1 environment variable.
#
# Before each JS feature spec: injects a monkey-patch on window.fetch and
# XMLHttpRequest to count pending requests.
# After each JS feature spec: warns if any requests are still in-flight.

if ENV['AJAX_DIAG'] == '1'
  AJAX_DIAG_INJECT_JS = <<~JS
    (function() {
      if (window.__ajaxDiagInstalled) return;
      window.__ajaxDiagInstalled = true;
      window.__pendingRequests = 0;
      window.__completedRequests = 0;
      window.__requestLog = [];

      // Monkey-patch fetch
      var originalFetch = window.fetch;
      window.fetch = function() {
        var url = (arguments[0] instanceof Request) ? arguments[0].url : String(arguments[0]);
        window.__pendingRequests++;
        window.__requestLog.push({type: 'fetch', url: url, time: Date.now(), state: 'started'});
        return originalFetch.apply(this, arguments).then(function(response) {
          window.__pendingRequests--;
          window.__completedRequests++;
          return response;
        }).catch(function(err) {
          window.__pendingRequests--;
          window.__completedRequests++;
          throw err;
        });
      };

      // Monkey-patch XMLHttpRequest
      var originalOpen = XMLHttpRequest.prototype.open;
      var originalSend = XMLHttpRequest.prototype.send;
      XMLHttpRequest.prototype.open = function() {
        this.__ajaxDiagUrl = arguments[1];
        return originalOpen.apply(this, arguments);
      };
      XMLHttpRequest.prototype.send = function() {
        var xhr = this;
        window.__pendingRequests++;
        window.__requestLog.push({type: 'xhr', url: xhr.__ajaxDiagUrl, time: Date.now(), state: 'started'});
        xhr.addEventListener('loadend', function() {
          window.__pendingRequests--;
          window.__completedRequests++;
        });
        return originalSend.apply(this, arguments);
      };
    })();
  JS

  RSpec.configure do |config|
    config.before(:each, type: :feature, js: true) do
      page.execute_script(AJAX_DIAG_INJECT_JS) rescue nil # rubocop:disable Style/RescueModifier
    end

    config.after(:each, type: :feature, js: true) do |example|
      begin
        pending_count = page.evaluate_script('window.__pendingRequests') || 0
        completed_count = page.evaluate_script('window.__completedRequests') || 0

        if pending_count > 0
          request_log = page.evaluate_script(
            'window.__requestLog.filter(function(r) { return r.state === "started" }).slice(-5)'
          ) || []

          warn "[AJAX_DIAG] #{example.full_description}"
          warn "  #{pending_count} pending request(s) at spec end (#{completed_count} completed)"
          request_log.each do |entry|
            warn "  in-flight: #{entry['type']} #{entry['url']}"
          end
        end
      rescue StandardError
        # Page may already be navigated away; ignore
      end
    end
  end
end

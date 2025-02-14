Sentry.init do |config|
  config.dsn = ENV['sentry_dsn']
  config.enabled_environments = %w[development staging production test]

  # Appends to IGNORE_DEFAULT array of exception classes that should never be sent to Sentry
  config.excluded_exceptions += ['WikiApi::PageFetchError'] # error code 429

  filter_patterns = [
    /Failed to fetch/, # Thrown when stop(X) button is clicked while API request being made
    /NetworkError when attempting to fetch resource/,
    /Network request failed/,
    # Known errors caused by Microsoft Outlook SafeSearch or bot crawlers that use the CefSharp library.
    /^Non-Error promise rejection captured with value: Object Not Found Matching Id:\d+, MethodName:simulateEvent, ParamCount:\d+$/,
    /^Non-Error promise rejection captured with value: Object Not Found Matching Id:\d+, MethodName:update, ParamCount:\d+$/
  ]

  config.before_send = lambda do |event, hint|
    exception = hint[:exception]

    if exception.is_a?(TypeError) && filter_patterns.any? { |pattern| exception.message.match?(pattern) }
      return nil
    end

    if exception.is_a?(TypeError)
      stacktrace = exception&.stacktrace
      if stacktrace
        stacktrace.frames.each do |frame|
          if frame.function&.include?('@webkit-masked-url')
            return nil
          end
          if frame.function&.include?('chrome-extension://')
            return nil
          end
        end
      end
    end

    event
  end
end

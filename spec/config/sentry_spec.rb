# frozen_string_literal: true

require 'rails_helper'

describe 'Sentry before_send configuration', type: :request do
  before do
    # Initialize Sentry for testing
    setup_sentry_test
  end

  after do
    # Clean up after each test
    teardown_sentry_test
  end

  let(:filter_patterns) do
    [
      /Failed to fetch/,
      /NetworkError when attempting to fetch resource/,
      /Network request failed/
    ]
  end

  it 'does not filter out normal events' do
    exception = StandardError.new('Something went wrong')
    Sentry.capture_exception(exception)

    expect(sentry_events.size).to eq(1)
    expect(last_sentry_event.exception.values.first.type).to eq('StandardError')
    expect(last_sentry_event.exception.values.first.value).to eq('Something went wrong')
  end

  it 'filters out WikiApi::PageFetchErrors' do
    exception = WikiApi::PageFetchError.new('User:RageSoss', 429)
    Sentry.capture_exception(exception)

    expect(sentry_events).to be_empty
  end

  it 'filters out TypeErrors with specific network-related messages' do
    filter_patterns.each do |pattern|
      exception = TypeError.new(pattern.source)
      Sentry.capture_exception(exception)

      expect(sentry_events).to be_empty
    end
  end

  it 'filters out events with stack traces containing @webkit-masked-url' do
    exception = TypeError.new('undefined is not an object')
    exception.set_backtrace([
                              '//hidden/:75:27:in @webkit-masked-url:',
                              '//hidden/:26:40:in getCurrentStore@webkit-masked-url:',
                              '//hidden/:108:54:in @webkit-masked-url:'
                            ])
    Sentry.capture_exception(exception)

    expect(sentry_events).to be_empty
  end
end

import '../app/assets/javascripts/sentry';

describe('unhandledrejection safety net', () => {
  test('wraps a non-Error rejection reason (e.g. a raw Response-like object) in a real Error', () => {
    window.Sentry.captureException = jest.fn();
    const event = new Event('unhandledrejection', { cancelable: true });
    event.reason = { status: 403, statusText: 'Forbidden' };

    window.dispatchEvent(event);

    expect(event.defaultPrevented).toBe(true);
    expect(window.Sentry.captureException).toHaveBeenCalledTimes(1);
    const [error, context] = window.Sentry.captureException.mock.calls[0];
    expect(error).toBeInstanceOf(Error);
    expect(error.message).toBe('Unhandled rejection: Forbidden');
    expect(context.extra.reason).toBe(event.reason);
  });

  test('leaves rejections that are already real Errors alone', () => {
    window.Sentry.captureException = jest.fn();
    const event = new Event('unhandledrejection', { cancelable: true });
    event.reason = new Error('already a real error');

    window.dispatchEvent(event);

    expect(event.defaultPrevented).toBe(false);
    expect(window.Sentry.captureException).not.toHaveBeenCalled();
  });

  test('falls back to a stringified reason when it has no status/statusText', () => {
    window.Sentry.captureException = jest.fn();
    const event = new Event('unhandledrejection', { cancelable: true });
    event.reason = { foo: 'bar' };

    window.dispatchEvent(event);

    const [error] = window.Sentry.captureException.mock.calls[0];
    expect(error.message).toBe('Unhandled rejection: {"foo":"bar"}');
  });
});

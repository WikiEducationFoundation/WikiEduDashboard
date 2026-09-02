import '../app/assets/javascripts/sentry';

const buildEvent = (value = 'Non-Error exception captured') => ({
  exception: {
    values: [
      { type: 'UnhandledRejection', value, mechanism: { type: 'onunhandledrejection', handled: false } },
    ],
  },
});

describe('normalizeUnhandledRejection (Sentry beforeSend)', () => {
  test('rewrites the message for a non-Error rejection reason (e.g. a Response-like object)', () => {
    const event = buildEvent();
    const hint = { originalException: { status: 403, statusText: 'Forbidden' } };

    const result = window.normalizeUnhandledRejection(event, hint);

    expect(result.exception.values[0].value).toBe('Unhandled rejection: Forbidden');
    expect(result.exception.values[0].type).toBe('UnhandledRejection');
  });

  test('falls back to a stringified reason when it has no status/statusText', () => {
    const event = buildEvent();
    const hint = { originalException: { foo: 'bar' } };

    const result = window.normalizeUnhandledRejection(event, hint);

    expect(result.exception.values[0].value).toBe('Unhandled rejection: {"foo":"bar"}');
  });

  test('leaves the event untouched when the rejection reason is already a real Error', () => {
    const event = buildEvent('some message');
    const hint = { originalException: new Error('already a real error') };

    const result = window.normalizeUnhandledRejection(event, hint);

    expect(result.exception.values[0].value).toBe('some message');
  });

  test('leaves the event untouched when the mechanism is not onunhandledrejection', () => {
    const event = {
      exception: {
        values: [{ type: 'Error', value: 'some message', mechanism: { type: 'onerror', handled: false } }],
      },
    };
    const hint = { originalException: { status: 500 } };

    const result = window.normalizeUnhandledRejection(event, hint);

    expect(result.exception.values[0].value).toBe('some message');
  });

  test('does not throw on an event with no exception values', () => {
    const event = {};
    expect(() => window.normalizeUnhandledRejection(event, {})).not.toThrow();
    expect(window.normalizeUnhandledRejection(event, {})).toBe(event);
  });

  test('enriches and aggregates an unhandled TypeError: Failed to fetch', () => {
    const event = buildEvent('TypeError: Failed to fetch');
    event.breadcrumbs = {
      values: [
        { category: 'fetch', level: 'error', data: { url: 'https://www.wikidata.org/w/api.php?action=wbgetentities' } },
      ],
    };
    const hint = { originalException: new TypeError('Failed to fetch') };

    const result = window.normalizeUnhandledRejection(event, hint);

    expect(result.fingerprint).toEqual(['unhandled-failed-to-fetch']);
    expect(result.tags).toEqual(expect.objectContaining({
      crossOrigin: true,
      hasServiceWorkerController: false,
    }));
    expect(typeof result.tags.onLine).toBe('boolean');
    expect(typeof result.tags.visibilityState).toBe('string');
    expect(result.extra.failedUrl).toBe('https://www.wikidata.org/w/api.php?action=wbgetentities');
    // The message itself is left alone -- only extra/tags/fingerprint are added.
    expect(result.exception.values[0].value).toBe('TypeError: Failed to fetch');
  });

  test('reports crossOrigin: false for a same-origin Failed to fetch', () => {
    const event = buildEvent('TypeError: Failed to fetch');
    event.breadcrumbs = {
      values: [
        { category: 'fetch', level: 'error', data: { url: `${window.location.origin}/stats_graphs.json` } },
      ],
    };
    const hint = { originalException: new TypeError('Failed to fetch') };

    const result = window.normalizeUnhandledRejection(event, hint);

    expect(result.tags.crossOrigin).toBe(false);
  });

  test('attributes the failed URL, not a later successful one settling after it', () => {
    // Breadcrumbs land in settle order, not failure order, so an unrelated
    // request settling after the failed one shouldn't win.
    const event = buildEvent('TypeError: Failed to fetch');
    event.breadcrumbs = {
      values: [
        // The request that actually failed.
        { category: 'fetch', level: 'error', data: { url: 'https://www.wikidata.org/w/api.php' } },
        // A same-origin request that merely settled afterwards.
        { category: 'fetch', data: { url: `${window.location.origin}/articles.json`, status_code: 200 } },
      ],
    };
    const hint = { originalException: new TypeError('Failed to fetch') };

    const result = window.normalizeUnhandledRejection(event, hint);

    expect(result.extra.failedUrl).toBe('https://www.wikidata.org/w/api.php');
    expect(result.tags.crossOrigin).toBe(true);
  });
});

describe('against a real initialized Sentry client', () => {
  test('a non-Error rejection produces exactly one event, with the readable message', () => {
    const captured = [];

    window.Sentry.init({
      dsn: 'https://examplePublicKey@o0.ingest.sentry.io/0',
      autoSessionTracking: false,
      beforeSend: (event, hint) => {
        const normalized = window.normalizeUnhandledRejection(event, hint);
        captured.push(normalized.exception.values[0].value);
        return null; // don't actually send
      },
    });

    const event = new Event('unhandledrejection', { cancelable: true });
    event.reason = { status: 403, statusText: 'Forbidden' };

    // Sentry 7.x instruments window.onunhandledrejection (the property handler),
    // not addEventListener — this is the only thing that fires, since sentry.js
    // no longer registers its own addEventListener('unhandledrejection', ...).
    window.onunhandledrejection(event);

    expect(captured).toEqual(['Unhandled rejection: Forbidden']);
  });
});

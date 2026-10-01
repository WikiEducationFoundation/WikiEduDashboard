import '../testHelper';
import * as requestModule from '../../app/assets/javascripts/utils/request';
import { fetchWikidataLabels } from '../../app/assets/javascripts/actions/wikidata_actions';
import { RECEIVE_WIKIDATA_LABELS } from '../../app/assets/javascripts/constants';

// Flush the microtask queue so the fire-and-forget promise chain inside
// fetchWikidataLabels has a chance to settle before assertions run.
const flushPromises = async () => {
  for (let i = 0; i < 10; i += 1) {
    await Promise.resolve();
  }
};

describe('fetchWikidataLabels', () => {
  afterEach(() => {
    if (requestModule.default.restore) requestModule.default.restore();
    delete global.Sentry;
  });

  test('dispatches RECEIVE_WIKIDATA_LABELS when the Wikidata request succeeds', async () => {
    const entities = { entities: { Q1: { labels: { en: { value: 'Example' } } } } };
    sinon.stub(requestModule, 'default').resolves({
      ok: true,
      json: () => Promise.resolve(entities),
    });
    const dispatch = jest.fn();

    fetchWikidataLabels([{ title: 'Q1' }], dispatch);
    await flushPromises();

    expect(dispatch).toHaveBeenCalledWith(expect.objectContaining({
      type: RECEIVE_WIKIDATA_LABELS,
      data: entities,
    }));
  });

  test('does not throw or leave an unhandled rejection when the Wikidata request fails (e.g. a 403)', async () => {
    sinon.stub(requestModule, 'default').resolves({
      ok: false,
      status: 403,
      statusText: 'Forbidden',
      text: () => Promise.resolve(''),
    });
    const dispatch = jest.fn();

    expect(() => fetchWikidataLabels([{ title: 'Q1' }], dispatch)).not.toThrow();
    await flushPromises();

    // The chunk's labels are skipped rather than dispatched or thrown.
    expect(dispatch).not.toHaveBeenCalled();
  });

  test('reports the failure to Sentry, since this request has no other .catch() upstream', async () => {
    sinon.stub(requestModule, 'default').resolves({
      ok: false,
      status: 403,
      statusText: 'Forbidden',
      url: 'https://www.wikidata.org/w/api.php?action=wbgetentities',
      text: () => Promise.resolve('blocked'),
    });
    global.Sentry = { captureException: jest.fn() };
    const dispatch = jest.fn();

    fetchWikidataLabels([{ title: 'Q1' }], dispatch);
    await flushPromises();

    expect(global.Sentry.captureException).toHaveBeenCalledWith(
      expect.objectContaining({ name: 'ApiError', status: 403, statusText: 'Forbidden' }),
      {
        tags: { onLine: true, visibilityState: 'visible', hasServiceWorkerController: false },
        extra: { requestUrl: 'https://www.wikidata.org/w/api.php?action=wbgetentities', responseText: 'blocked' },
      }
    );
  });

  test('reports requestUrl/onLine/visibilityState/hasServiceWorkerController for a network-level failure (e.g. Failed to fetch)', async () => {
    sinon.stub(requestModule, 'default').rejects(new TypeError('Failed to fetch'));
    global.Sentry = { captureException: jest.fn() };
    const dispatch = jest.fn();

    fetchWikidataLabels([{ title: 'Q1' }], dispatch);
    await flushPromises();

    expect(global.Sentry.captureException).toHaveBeenCalledWith(
      expect.objectContaining({ name: 'TypeError', message: 'Failed to fetch' }),
      {
        tags: { onLine: true, visibilityState: 'visible', hasServiceWorkerController: false },
        extra: {
          requestUrl: expect.stringContaining('https://www.wikidata.org/w/api.php'),
          responseText: undefined,
        },
      }
    );
  });

  test('limits chunk requests in flight instead of firing all of them at once', async () => {
    const entities = { entities: {} };
    const stub = sinon.stub(requestModule, 'default').resolves({
      ok: true,
      json: () => Promise.resolve(entities),
    });
    const dispatch = jest.fn();
    // 7 chunks of 30 qNumbers each (210 entities) should run with at most
    // CONCURRENCY_LIMIT (3) requests in flight, not all 7 at once.
    const entitiesList = Array.from({ length: 210 }, (_, i) => ({ title: `Q${i}` }));

    fetchWikidataLabels(entitiesList, dispatch);
    // Right after kicking things off, only the first batch should have
    // started — before any promise in that batch has resolved.
    expect(stub.callCount).toBeLessThanOrEqual(3);

    // The concurrency-limited runner recurses one chunk at a time, so each of
    // the later chunks needs a few more microtask turns to kick off than a
    // single flushPromises() provides.
    await flushPromises();
    await flushPromises();
    expect(stub.callCount).toBe(7);
  });
});

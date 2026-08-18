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
});

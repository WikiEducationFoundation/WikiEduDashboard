import '../testHelper';
import * as requestModule from '../../app/assets/javascripts/utils/request';
import { fetchClassFromRevisions } from '../../app/assets/javascripts/utils/media_wiki_classes';

describe('fetchClassFromRevisions', () => {
  afterEach(() => {
    if (requestModule.default.restore) requestModule.default.restore();
  });

  const revision = { ns: 0, title: 'Foo', pageid: 1, revid: 100, wiki: { project: 'wikipedia', language: 'en' } };
  const wikiMap = new Map([['en.wikipedia.org', [revision]]]);

  test('resolves with assessments when the request succeeds', async () => {
    sinon.stub(requestModule, 'default').resolves({
      ok: true,
      json: () => Promise.resolve({
        query: { pages: { 1: { pageassessments: { WikiProject: { class: 'FA' } } } } },
      }),
    });

    const result = await fetchClassFromRevisions(wikiMap);

    expect(result).toEqual({ 100: { rating: 'fa', pretty_rating: 'FA', rating_num: 100 } });
  });

  test('does not throw or leave an unhandled rejection when the request fails (e.g. Failed to fetch)', async () => {
    sinon.stub(requestModule, 'default').rejects(new TypeError('Failed to fetch'));

    // The revision is still present in the result, just with no rating resolved.
    await expect(fetchClassFromRevisions(wikiMap)).resolves.toEqual({ 100: {} });
  });

  test('one failing wiki does not prevent assessments from other wikis in the batch', async () => {
    const okRevision = { ns: 0, title: 'Ok', pageid: 2, revid: 200, wiki: { project: 'wikipedia', language: 'en' } };
    const twoWikiMap = new Map([
      ['broken.wikipedia.org', [revision]],
      ['ok.wikipedia.org', [okRevision]],
    ]);
    const stub = sinon.stub(requestModule, 'default');
    stub.withArgs(sinon.match(/broken\.wikipedia\.org/)).rejects(new TypeError('Failed to fetch'));
    stub.withArgs(sinon.match(/ok\.wikipedia\.org/)).resolves({
      ok: true,
      json: () => Promise.resolve({ query: { pages: { 2: { pageassessments: { WikiProject: { class: 'FA' } } } } } }),
    });

    const result = await fetchClassFromRevisions(twoWikiMap);

    expect(result).toEqual({
      100: {},
      200: { rating: 'fa', pretty_rating: 'FA', rating_num: 100 },
    });
  });
});

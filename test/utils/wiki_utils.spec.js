import '../testHelper';
import { formatOption, toWikiDomain, trackedWikisMaker, overviewStatsTitle } from '../../app/assets/javascripts/utils/wiki_utils';


describe('formatOption', () => {
  test(
    'formats wiki data',
    () => {
      const wikiData = {
        language: 'en',
        project: 'wikipedia'
      };
      const result = formatOption(wikiData);
      expect(result).toStrictEqual({ label: 'en.wikipedia.org', value: '{"language":"en","project":"wikipedia"}' });
    }
  );
});

describe('url', () => {
  test(
    'returns url format',
    () => {
      const wikiData = {
        language: 'en',
        project: 'wikipedia'
      };
      const result = toWikiDomain(wikiData);
      expect(result).toStrictEqual('en.wikipedia.org');
    }
  );
  test(
    'if no language specified, returns www subdomain',
    () => {
      const wikiData = {
        language: null,
        project: 'wikipedia'
      };
      const result = toWikiDomain(wikiData);
      expect(result).toStrictEqual('www.wikipedia.org');
    }
  );
});

describe('trackedWikisMaker', () => {
  test(
    'if course includes wikis data, creates an array of tracked Wikis objects',
    () => {
      const course = {
        wikis: [{
          language: 'en',
          project: 'wikipedia'
        }, {
          language: null,
          project: 'wikipedia'
        }]
      };
  const result = trackedWikisMaker(course);
  expect(result).toStrictEqual([{ label: 'en.wikipedia.org', value: '{"language":"en","project":"wikipedia"}' }, { label: 'www.wikipedia.org', value: '{"language":"www","project":"wikipedia"}' }]);
    }
  );
  test(
    'if course does not include wikis data, returns an empty array',
    () => {
      const course = 'no Wikis here';
      const result = trackedWikisMaker(course);
      expect(result).toStrictEqual([]);
    }
  );
});

describe('overviewStatsTitle', () => {
  test(
    'returns title in form of \'wiki - namespace\' if stats are for a tracked namespace',
    () => {
      const wiki_ns_key = 'en.wikibooks.org-namespace-102';
      const result = overviewStatsTitle(wiki_ns_key);
      const expected = 'en.wikibooks.org - Cookbook';
      expect(result).toBe(expected);
    });
  test(
    'returns wiki domain as title if stats are for wikidata overview',
    () => {
      const wiki_ns_key = 'www.wikidata.org';
      const result = overviewStatsTitle(wiki_ns_key);
      const expected = 'www.wikidata.org';
      expect(result).toBe(expected);
    });
});

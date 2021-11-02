import '../testHelper';
import { formatOption, url } from '../../app/assets/javascripts/utils/wiki_utils';


describe('formatOption', () => {
  test(
    'formats wiki data',
    () => {
      const wikiData = {
        "language": "en",
        "project": "wikipedia"
      };
      const result = formatOption(wikiData);
      expect(result).toStrictEqual( {"label": "en.wikipedia.org", "value": "{\"language\":\"en\",\"project\":\"wikipedia\"}"});
    }
  );
});

describe('url', () => {
  test(
    'returns url format',
    () => {
      const wikiData = {
        "language": "en",
        "project": "wikipedia"
      };
      const result = url(wikiData);
      expect(result).toStrictEqual("en.wikipedia.org");
    }
  );
  test(
    'if no language specified, returns www subdomain',
    () => {
      const wikiData = {
        "language": null,
        "project": "wikipedia"
      };
      const result = url(wikiData);
      expect(result).toStrictEqual("www.wikipedia.org");
    }
  );
});
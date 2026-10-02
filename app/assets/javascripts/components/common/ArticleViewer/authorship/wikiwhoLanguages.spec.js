import { WIKIWHO_LANGUAGES, isWikiwhoSupported } from './wikiwhoLanguages';

describe('WIKIWHO_LANGUAGES', () => {
  it('contains no duplicate language codes', () => {
    expect(new Set(WIKIWHO_LANGUAGES).size).toEqual(WIKIWHO_LANGUAGES.length);
  });

  it('includes the non-standard "simple" code used by Simple English Wikipedia', () => {
    expect(WIKIWHO_LANGUAGES).toContain('simple');
  });
});

describe('isWikiwhoSupported', () => {
  it('is true for a supported language on Wikipedia', () => {
    expect(isWikiwhoSupported({ language: 'en', project: 'wikipedia' })).toBe(true);
  });

  it('is true for languages the service added after the original list was written', () => {
    ['ru', 'sv', 'uk', 'vec', 'zh'].forEach((language) => {
      expect(isWikiwhoSupported({ language, project: 'wikipedia' })).toBe(true);
    });
  });

  it('is false for a Wikipedia language the service does not cover', () => {
    // Norwegian Nynorsk has a Wikipedia but no WikiWho endpoint.
    expect(isWikiwhoSupported({ language: 'nn', project: 'wikipedia' })).toBe(false);
  });

  it('is false for non-Wikipedia projects even in a supported language', () => {
    expect(isWikiwhoSupported({ language: 'en', project: 'wikisource' })).toBe(false);
  });

  it('is false when the article has no language', () => {
    expect(isWikiwhoSupported({ language: null, project: 'wikipedia' })).toBe(false);
  });
});

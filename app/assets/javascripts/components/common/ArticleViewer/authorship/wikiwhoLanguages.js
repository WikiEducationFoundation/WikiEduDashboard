/*
  Wikipedia language editions covered by the WikiWho / WhoColor API at
  https://wikiwho-api.wmcloud.org.

  The service adds languages over time, so this list goes stale. To refresh it,
  read the language codes out of the per-language endpoint URLs listed on the
  service's index page:

    curl -s https://wikiwho-api.wmcloud.org/ \
      | grep -oE '/[a-z-]+/whocolor/v1\.0\.0-beta' \
      | sed 's|/whocolor.*||; s|^/||' | sort -u

  Codes not on the list return 404 from the WhoColor endpoint, which is why we
  gate on it rather than letting every request through.

  Last verified against the live service: 2026-08-07 (70 languages).
*/
export const WIKIWHO_LANGUAGES = [
  'af', 'als', 'ar', 'az', 'be', 'bg', 'bn', 'bs', 'ce', 'cs',
  'cy', 'da', 'de', 'dsb', 'el', 'en', 'eo', 'es', 'et', 'eu',
  'fa', 'fi', 'fr', 'gl', 'he', 'hi', 'hr', 'hu', 'ia', 'id',
  'it', 'ja', 'ka', 'kk', 'ko', 'ku', 'lt', 'lv', 'mk', 'ml',
  'mr', 'ms', 'mt', 'ne', 'nl', 'no', 'pl', 'pt', 'ro', 'ru',
  'sh', 'simple', 'sk', 'sl', 'sq', 'sr', 'sv', 'sw', 'ta', 'te',
  'tg', 'th', 'tl', 'tr', 'uk', 'ur', 'uz', 'vec', 'vi', 'zh',
];

// WhoColor only covers Wikipedia. Other projects (Wiktionary, Wikisource, etc.)
// have no authorship data even when their language code appears above.
export const isWikiwhoSupported = article => (
  article.project === 'wikipedia' && WIKIWHO_LANGUAGES.includes(article.language)
);

export default WIKIWHO_LANGUAGES;

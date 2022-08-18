import { I18n } from 'i18n-js';

async function loadTranslations(i18n, locale) {
  const response = await fetch(`/assets/javascripts/i18n/${locale}.json`);
  const translations = await response.json();
  i18n.store(translations);
}

export default async () => {
  const i18n = new I18n();


  await loadTranslations(i18n, window.locale);

  // all of these are set in app/views/layouts/stats.html.haml and app/views/shared/_head.html.haml
  i18n.locale = window.locale;
  i18n.defaultLocale = window.defaultLocale;
  i18n.availableLocales = window.availableLocales;
  i18n.enableFallback = true;

  window.I18n = i18n;
};


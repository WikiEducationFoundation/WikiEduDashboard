import { I18n } from 'i18n-js';

const i18n = new I18n(window.locale_json);
// all of these are set in app/views/layouts/stats.html.haml and app/views/shared/_head.html.haml
i18n.locale = window.locale;
i18n.defaultLocale = window.defaultLocale;
i18n.availableLocales = window.availableLocales;
i18n.enableFallback = true;

window.I18n = i18n;


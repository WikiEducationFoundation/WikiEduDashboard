import enJSON from '../public/assets/javascripts/i18n/en.json';

import { I18n } from 'i18n-js';

const i18n = new I18n(enJSON);
global.I18n = i18n;
i18n.locale = 'en';
i18n.defaultLocale = 'en';
i18n.enableFallback = true;

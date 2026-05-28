import { I18n } from 'i18n-js';


const i18n = new I18n();
i18n.enableFallback = true;

window.i18n = i18n;
window.I18n = i18n;
export default i18n;

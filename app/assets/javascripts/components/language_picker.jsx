import React from 'react';
import Select from 'react-select';
import _ from 'lodash';
import languageNames from '../utils/language_names';

const getNativeName = (code) => {
  const language = languageNames[code];
  if (!language) { return ''; }
  return language.nativeName;
};

class LanguagePicker extends React.Component {
  selectLanguage(locale) {
    const name = locale.value;
    if (name === 'help_translate') {
      window.open('https://translatewiki.net/wiki/Translating:Wiki_Ed_Dashboard');
      return;
    }
    if (window.currentUser.id !== '') {
      $.post(`/update_locale/${name}`, () => {
        location.reload();
      });
    } else {
      window.location = `?locale=${name}`;
    }
  }
  render() {
    const enN = getNativeName('en');
    const esN = getNativeName('es');
    const frN = getNativeName('fr');

    const popularLocales = [
      { label: enN, value: 'en' },
      { label: esN, value: 'es' },
      { label: frN, value: 'fr' },
    ];

    const translateLink = [
      { label: 'Help translate', value: 'help_translate' },
    ];

    const allLocales = _.compact(I18n.availableLocales).map((code) => {
      const nativeName = getNativeName(code);
      if (nativeName !== enN && nativeName !== esN && nativeName !== frN) {
        return { label: nativeName || code, value: code };
      }
      return undefined;
    });

    const defLocales = _.without(allLocales, undefined);
    const newLocales = translateLink.concat(popularLocales).concat(defLocales);
    const curLocale = <span><img src="/assets/images/icon-language.png" alt="Translate this page" /> {I18n.locale} </span>;

    return (
      <span className="language-picker">
        <Select
          name="language-picker"
          placeholder={curLocale}
          options={newLocales}
          onChange={this.selectLanguage}
          clearable={false}
        />
      </span>
    );
  }
}

export default LanguagePicker;

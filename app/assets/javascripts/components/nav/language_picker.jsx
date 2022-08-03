import React from 'react';
import Select from 'react-select';
import { compact, without } from 'lodash-es';
import languageNames from '../../utils/language_names';
import selectStyles from '../../styles/select';
import request from '../../utils/request';

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
      request(`/update_locale/${name}`, {
        method: 'POST',
      }).then(req => req.text()).then(() => {
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

    const allLocales = compact(I18n.availableLocales).map((code) => {
      const nativeName = getNativeName(code);
      if (nativeName !== enN && nativeName !== esN && nativeName !== frN) {
        return { label: nativeName || code, value: code };
      }
      return undefined;
    });

    const defLocales = without(allLocales, undefined);
    const newLocales = translateLink.concat(popularLocales).concat(defLocales);
    const curLocale = <span><img src="/assets/images/icon-language.png" alt="Translate this page" /> {I18n.locale} </span>;

    return (
      <span className="language-picker">
        <Select
          name="language-picker"
          classNamePrefix="language-picker"
          placeholder={curLocale}
          options={newLocales}
          onChange={this.selectLanguage}
          clearable={false}
          styles={selectStyles}
        />
      </span>
    );
  }
}

export default LanguagePicker;

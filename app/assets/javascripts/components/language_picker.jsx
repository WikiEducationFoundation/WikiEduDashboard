import React from 'react';
import Select from 'react-select-plus';
import iso from 'iso-639-1';
import _ from 'lodash';

class LanguagePicker extends React.Component {
  selectLanguage(locale) {
    const name = locale.value;
    if(name == "help_translate") {
      window.open("https://translatewiki.net/");
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
    const enN = iso.getNativeName("en");
    const esN = iso.getNativeName("es");
    const frN = iso.getNativeName("fr");

    const popularLocales = [
      { label: enN, value: "en" },
      { label: esN, value: "es" },
      { label: frN, value: "fr" },
    ];

    const translateLink = [
      { label: "Help translate", value: 'help_translate'},
    ];

    const allLocales = _.compact(I18n.availableLocales).map(code => {
      const nativeName = iso.getNativeName(code);
      if (nativeName && (nativeName !== enN && nativeName !== esN && nativeName !== frN)) {
        return { label: nativeName, value: code };
      }
      return undefined;
    });

    const defLocales = _.without(allLocales, undefined);
    const newLocales = translateLink.concat(popularLocales).concat(defLocales);
    const curLocale = <span><img src="../../assets/images/icon-language.png"/> {I18n.locale} </span>;

    return (
      <div className="language-picker">
        <Select
          name="language-picker"
          placeholder={curLocale}
          options={newLocales}
          onChange={this.selectLanguage}
          searchable={false}
          clearable={false}
        />
      </div>
    );
  }
}

export default LanguagePicker;

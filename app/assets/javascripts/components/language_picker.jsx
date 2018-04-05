import React from 'react';
import Select from 'react-select-plus';
import iso from 'iso-639-1';
import _ from 'lodash';

class LanguagePicker extends React.Component {
  constructor() {
    super();
    this.state = {
      curLocale: iso.getNativeName(I18n.locale)
    };
    this.selectLanguage = this.selectLanguage.bind(this);
    this.render = this.render.bind(this);
  }
  selectLanguage(locale) {
    if (window.currentUser.id !== '') {
      const name = locale.value;
      this.setState({ curLocale: name });
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

    const allLocales = _.compact(I18n.availableLocales).map(code => {
      const nativeName = iso.getNativeName(code);
      if (nativeName && (nativeName !== enN && nativeName !== esN && nativeName !== frN)) {
        return { label: nativeName, value: code };
      }
      return undefined;
    });

    const defLocales = _.without(allLocales, undefined);
    const newLocales = popularLocales.concat(defLocales);

    return (
      <div className="language-picker">
        <Select
          name="language-picker"
          value={this.state.curLocale}
          placeholder={this.state.curLocale}
          options={newLocales}
          onChange={this.selectLanguage}
        />
      </div>
    );
  }
}

export default LanguagePicker;

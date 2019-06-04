import React from 'react';
import createReactClass from 'create-react-class';
import AsyncSelect from 'react-select/lib/Async';
import PropTypes from 'prop-types';

const options = [];
/**
 *  A Wiki Selector Component that combines both language and project into a singular searchable
 *  component that works for both single-wiki and multi-wiki.
 */
const WikiSelect = createReactClass({
  propTypes: {
    /**
     *  If true multiple wiki can be selected.
     */
    multi: PropTypes.bool,
    /**
     *  callback(wiki); where wiki is { language, project } if multi = false else Array of { language, project }
     */
    onChange: PropTypes.func,
    /**
     *  Custom styles for the Select Widget.
     */
    styles: PropTypes.object,
    /**
     *  An array of { language, project }
     */
    wikis: PropTypes.array
  },

  render() {
    if (options.length === 0) {
      // cache the options so it doesn't run on every render
      const languages = JSON.parse(WikiLanguages);
      const projects = JSON.parse(WikiProjects).filter(proj => proj !== 'wikidata');
      for (let i = 0; i < languages.length; i += 1) {
        for (let j = 0; j < projects.length; j += 1) {
          const language = languages[i];
          const project = projects[j];
          options.push({ value: { language, project }, label: `${language}.${project}.org` });
        }
      }
      // Wikidata is multilingual with English as the default language and therefore has
      // a custom label so it is more intuitive.
      options.push({ value: { language: 'en', project: 'wikidata' }, label: 'www.wikidata.org' });
    }


    // Used to set the already available wikis
    let wikis = [];
    if (this.props.wikis) {
      wikis = this.props.wikis.map((wiki) => {
        return {
          value: wiki,
          label: `${wiki.language}.${wiki.project}.org`
        };
      });
    }

    const filterOptions = function (val) {
      return options.filter(wiki =>
        wiki.label.toLowerCase().includes(val.toLowerCase())
      ).slice(0, 10); // limit the options for better performance
    };

    const loadOptions = function (inputValue, callback) {
      if (inputValue.trim().length > 1) {
        callback(filterOptions(inputValue));
      } else {
        callback([]);
      }
    };

    const getNoOptionsMessage = (val) => {
      const rem = 2 - val.inputValue.length;
      if (rem > 0) {
        return I18n.t('multi_wiki.selector_suggestion', { remaining: rem });
      }
      return I18n.t('application.no_results', { query: val.inputValue });
    };

    return <AsyncSelect
      isMulti={this.props.multi}
      placeholder={I18n.t('multi_wiki.selector_placeholder')}
      defaultValue={wikis}
      noOptionsMessage={getNoOptionsMessage}
      loadOptions={loadOptions}
      isSearchable={true}
      onChange={this.props.onChange}
      styles={this.props.styles}
      isClearable={false}
    />;
  }
}
);

export default WikiSelect;


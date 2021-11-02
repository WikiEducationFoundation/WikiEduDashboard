import React from 'react';
import createReactClass from 'create-react-class';
import AsyncSelect from 'react-select/async';
import PropTypes from 'prop-types';
import { map } from 'lodash-es';
import ArrayUtils from '../../utils/array_utils';


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
    wikis: PropTypes.array,
    /**
     *  Home Wiki, a object { language, project }. Required if multi=true
     */
    homeWiki: PropTypes.object,
    /**
     *  Should the Wikis be read-only
     */
    readOnly: PropTypes.bool,
    /**
     * Wikis for options, in article finder (through selected_wiki_options)
     * and assign button (through new assigment input and selected wiki options)  tracked Wikis,
     * in details and couse_form all Wikis
    */
    options: PropTypes.array
  },

  formatOption(wiki) {
    return {
      value: JSON.stringify(wiki),
      label: this.url(wiki)
    };
  },

  url(wiki) {
    const subdomain = wiki.language || 'www';
    return `${subdomain}.${wiki.project}.org`;
  },

  render() {
    if (this.props.readOnly) {
      const lastIndex = this.props.wikis.length - 1;

      const wikiList = map(this.props.wikis, (wiki, index) => {
        const comma = (index !== lastIndex) ? ', ' : '';
        const wikiUrl = this.url(wiki);
        return <span key={wikiUrl}>{wikiUrl}{comma}</span>;
      });
      return (
        <>
          {wikiList}
        </>
      );
    }

    // Used to set the already available wikis
    let wikis = [];
    if (this.props.wikis) {
      wikis = this.props.wikis.map((wiki) => {
        wiki.language = wiki.language || 'www'; // for multilingual wikis language is null
        return this.formatOption(wiki);
      });
    }

    // Home Wiki should appear first in the list of tracked wikis as in any other place it blocks
    // the removal of a wiki via backspace. Removing a wiki by pressing 'X' still works
    // but is bad UI and home wiki appearing first makes more sense anyway.
    let home_wiki = this.props.homeWiki;
    if (this.props.multi) {
      home_wiki = this.formatOption(home_wiki);
      wikis = ArrayUtils.removeObject(wikis, home_wiki);
      wikis.unshift(home_wiki);
    }

    const preprocess = (wiki) => {
      if (wiki) {
        if (this.props.multi) {
          wiki = wiki.map((w) => { return { value: JSON.parse(w.value), label: w.label }; });
        } else {
          const value = JSON.parse(wiki.value);
          wiki = { label: wiki.label, value };
        }
        this.props.onChange(wiki);
      } else {
        this.props.onChange(this.props.multi ? [] : {});
      }
    };
    const options = this.props.options;
    const filterOptions = function (val) {
      return options.filter(wiki =>
        wiki.label.toLowerCase().includes(val.toLowerCase())
      ).slice(0, 10); // limit the options for better performance
    };

    const loadOptions = function (inputValue, callback) {
      callback(filterOptions(inputValue));
    };

    return <AsyncSelect
      isMulti={this.props.multi}
      placeholder={I18n.t('multi_wiki.selector_placeholder')}
      noOptionsMessage={() => I18n.t('multi_wiki.selector_placeholder')}
      value={wikis}
      loadOptions={loadOptions}
      onChange={preprocess}
      styles={this.props.styles}
      isClearable={false}
    />;
  }
}
);

export default WikiSelect;


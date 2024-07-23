import React, { useCallback } from 'react';
import AsyncSelect from 'react-select/async';
import PropTypes from 'prop-types';
import { map } from 'lodash-es';
import ArrayUtils from '../../utils/array_utils';
import WIKI_OPTIONS from '../../utils/wiki_options';
import { formatOption } from '../../utils/wiki_utils';

/**
 *  A Wiki Selector Component that combines both language and project into a singular searchable
 *  component that works for both single-wiki and multi-wiki.
 */
const WikiSelect = ({ multi, onChange, styles, wikis, homeWiki, readOnly, label, id, options }) => {
  // Function to generate URL for a wiki
  const url = useCallback((wiki) => {
    const subdomain = wiki.language || 'www';
    return `${subdomain}.${wiki.project}.org`;
  }, []);

  if (readOnly) {
    const lastIndex = wikis.length - 1;
    const wikiList = map(wikis, (wiki, index) => {
      const comma = (index !== lastIndex) ? ', ' : '';
      const wikiUrl = url(wiki);
      return <span key={wikiUrl}>{wikiUrl}{comma}</span>;
    });

    return (
      <>
        {wikiList}
      </>
    );
  }

  // Used to set the already available wikis
  let formattedWikis = [];
  if (wikis) {
    formattedWikis = wikis.map((wiki) => {
      wiki.language = wiki.language || 'www'; // for multilingual wikis language is null
      return formatOption(wiki);
    });
  }

  // Home Wiki should appear first in the list of tracked wikis
  let formattedHomeWiki = homeWiki;
  if (multi) {
    formattedHomeWiki = formatOption(homeWiki);
    formattedWikis = ArrayUtils.removeObject(formattedWikis, formattedHomeWiki);
    formattedWikis.unshift(formattedHomeWiki);
  }

  const preprocess = (wiki) => {
    if (wiki) {
      if (multi) {
        wiki = wiki.map((w) => { return { value: JSON.parse(w.value), label: w.label }; });
      } else {
        const value = JSON.parse(wiki.value);
        wiki = { label: wiki.label, value };
      }
      onChange(wiki);
    } else {
      onChange(multi ? [] : {});
    }
  };

// If the component was passed a set of wikis as options, limit the options to those wikis.
// Otherwise, allow any wiki to be selected.
  const wikiOptions = (options && options.length) ? options : WIKI_OPTIONS;

  // If the input is less than three characters, it will be matched from the beginning of the string.
  const filterOptionsShort = (val) => {
    return wikiOptions.filter(wiki =>
      wiki.label.toLowerCase().includes(val.toLowerCase())
    ).slice(0, 10); // limit the options for better performance
  };

  // If the input is at least three characters, it will be matched anywhere in the string
  const filterOptionsLong = (val) => {
    return wikiOptions.filter(wiki =>
      wiki.label.toLowerCase().includes(val.toLowerCase())
    ).slice(0, 10);
  };

  const loadOptions = (inputValue, callback) => {
    if (inputValue.length < 3) {
      callback(filterOptionsShort(inputValue));
    }
    callback(filterOptionsLong(inputValue));
  };

  return (
    <>
      <label
        id={`${id}-label`}
        htmlFor={id} className="text-input-component__label"
      >
        <strong>
          {label}:&nbsp;
        </strong>
      </label>
      <AsyncSelect
        id={id}
        isMulti={multi}
        placeholder={I18n.t('multi_wiki.selector_placeholder')}
        noOptionsMessage={() => I18n.t('multi_wiki.selector_placeholder')}
        value={formattedWikis.length ? formattedWikis : undefined}
        loadOptions={loadOptions}
        onChange={preprocess}
        styles={styles}
        isClearable={false}
        defaultValue={formattedHomeWiki && formatOption(formattedHomeWiki)}
        className="multi-wiki-selector"
        aria-labelledby={`${id}-label`}
      />
    </>
  );
};

WikiSelect.propTypes = {
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
   *  Label for the select input
   */
  label: PropTypes.string,
  /**
   *  Label for the select input
   */
  id: PropTypes.string,
  /**
   * Wikis for options, in article finder (through selected_wiki_options)
   * and assign button (through new assigment input and selected wiki options) tracked Wikis,
   * in details and couse_form all Wikis
  */
  options: PropTypes.array
};

export default WikiSelect;

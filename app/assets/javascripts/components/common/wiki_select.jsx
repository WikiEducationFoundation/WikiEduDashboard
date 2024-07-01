import React, { useCallback } from 'react';
import AsyncSelect from 'react-select/async';
import PropTypes from 'prop-types';
import { map } from 'lodash-es';
import ArrayUtils from '../../utils/array_utils';
import WIKI_OPTIONS from '../../utils/wiki_options';
/**
 *  A Wiki Selector Component that combines both language and project into a singular searchable
 *  component that works for both single-wiki and multi-wiki.
 */
const WikiSelect = ({ multi, onChange, styles, wikis, homeWiki, readOnly, label, id, options }) => {
  // Function to format wiki option
  const formatOption = useCallback((wiki) => {
    return {
      value: JSON.stringify(wiki),
      label: url(wiki)
    };
  }, []);
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

  const wikiOptions = (options && options.length) ? options : WIKI_OPTIONS;

  const filterOptionsLong = (val) => {
    return wikiOptions.filter(wiki =>
      wiki.label.toLowerCase().includes(val.toLowerCase())
    ).slice(0, 10); // limit the options for better performance
  };

  const filterOptionsShort = (val) => {
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
  multi: PropTypes.bool,
  onChange: PropTypes.func,
  styles: PropTypes.object,
  wikis: PropTypes.array,
  homeWiki: PropTypes.object,
  readOnly: PropTypes.bool,
  label: PropTypes.string,
  id: PropTypes.string,
  options: PropTypes.array
};

export default WikiSelect;

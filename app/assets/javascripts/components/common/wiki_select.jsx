import React from 'react';
import createReactClass from 'create-react-class';
import AsyncSelect from 'react-select/lib/Async';
import PropTypes from 'prop-types';
import WIKI_OPTIONS from '../../utils/wiki_options';

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
      return WIKI_OPTIONS.filter(wiki =>
        wiki.label.toLowerCase().includes(val.toLowerCase())
      ).slice(0, 10); // limit the options for better performance
    };

    const loadOptions = function (inputValue, callback) {
        callback(filterOptions(inputValue));
    };

    return <AsyncSelect
      isMulti={this.props.multi}
      placeholder={I18n.t('multi_wiki.selector_placeholder')}
      defaultValue={wikis}
      loadOptions={loadOptions}
      defaultOptions={WIKI_OPTIONS.slice(0, 10)}
      isSearchable={true}
      onChange={this.props.onChange}
      styles={this.props.styles}
      isClearable={false}
    />;
  }
}
);

export default WikiSelect;


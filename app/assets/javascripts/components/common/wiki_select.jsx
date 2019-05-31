import React from 'react';
import createReactClass from 'create-react-class';
import Select, { createFilter } from 'react-select';
import PropTypes from 'prop-types';

const WikiSelect = createReactClass({
  propTypes: {
    multi: PropTypes.bool,
    onChange: PropTypes.func,
    styles: PropTypes.object,
    defaultLanguage: PropTypes.string,
    defaultValue: PropTypes.string
  },

  render() {
    const options = [];
    const languages = JSON.parse(WikiLanguages);
    const projects = JSON.parse(WikiProjects);
    const defaultValue = {
      value: {
        language: this.props.defaultLanguage,
        project: this.props.defaultProject
      },
      label: `${this.props.defaultLanguage}.${this.props.defaultProject}.org`
    };

    for (let i = 0; i < languages.length; i += 1) {
      for (let j = 0; j < projects.length; j += 1) {
        const language = languages[i];
        const project = projects[j];
        options.push({ value: { language, project }, label: `${language}.${project}.org` });
      }
    }

    return <Select
      isMulti={this.props.multi}
      defaultValue={defaultValue}
      options={options}
      isSearchable={true}
      filterOption={createFilter({ ignoreAccents: true, ignoreCase: true, trim: false })}
      onChange={this.props.onChange}
      styles={this.props.styles}
      isClearable={false}
      captureMenuScroll={false}
    />;
  }
}
);

export default WikiSelect;


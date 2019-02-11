import React from 'react';
import createReactClass from 'create-react-class';
import PropTypes from 'prop-types';
import Select from 'react-select';
import uuid from 'uuid';
import selectStyles from '../../styles/single_select';

const HomeWikiLanguageSelector = createReactClass({
  propTypes: {
    homeWiki: PropTypes.object,
    updateCourse: PropTypes.func.isRequired
  },

  getInitialState() {
    return { id: uuid.v4(),
      selectedOption: { value: this.props.course.home_wiki.language, label: this.props.course.home_wiki.language }, };
  },

  _handleChange(selectedOption) {
    const course = this.props.course;
    const homeWikiLanguage = selectedOption.value;
    course.home_wiki.language = homeWikiLanguage;
    this.setState({ selectedOption });
    return this.props.updateCourse(course);
  },

  render() {
    const options = JSON.parse(WikiLanguages).map((language) => {
      return { value: language, label: language };
    });
    const selector = (
      <div className="form-group">
        <label htmlFor={this.state.id}>{I18n.t('courses.home_wiki_language')}:</label>
        <Select
          id={this.state.id}
          value={options.find(option => option.value === this.state.selectedOption.value)}
          onChange={this._handleChange}
          options={options}
          simpleValue
          styles={selectStyles}
        />
      </div>
    );

    return (
      <div className="home_wiki_language_selector">
        {selector}
      </div>
    );
  }
});

export default HomeWikiLanguageSelector;

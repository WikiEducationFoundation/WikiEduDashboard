import React from 'react';
import createReactClass from 'create-react-class';
import PropTypes from 'prop-types';
import uuid from 'uuid';
import CourseActions from '../../actions/course_actions.js';

const HomeWikiLanguageSelector = createReactClass({
  propTypes: {
    homeWiki: PropTypes.object
  },

  componentWillMount() {
    this.setState({
      id: uuid.v4()
    });
  },

  _handleChange(e) {
    const course = this.props.course;
    const homeWikiLanguage = e.target.value;
    course.home_wiki.language = homeWikiLanguage;
    CourseActions.updateCourse(course);
  },

  render() {
    const options = JSON.parse(WikiLanguages).map((language, index) => {
      return (<option value={language} key={index}>{language}</option>);
    });

    const selector = (
      <div className="form-group">
        <label htmlFor={this.state.id}>{I18n.t('courses.home_wiki_language')}:</label>
        <select
          id={this.state.id}
          name="home_wiki_Language"
          value={this.props.course.home_wiki.language}
          onChange={this._handleChange}
        >
          {options}
        </select>
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

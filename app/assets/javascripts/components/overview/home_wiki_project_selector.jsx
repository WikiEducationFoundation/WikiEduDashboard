import React from 'react';
import createReactClass from 'create-react-class';
import PropTypes from 'prop-types';
import uuid from 'uuid';

const HomeWikiProjectSelector = createReactClass({
  propTypes: {
    course: PropTypes.object,
    updateCourse: PropTypes.func.isRequired
  },

  componentWillMount() {
    this.setState({
      id: uuid.v4()
    });
  },

  _handleChange(e) {
    const course = this.props.course;
    const homeWikiProject = e.target.value;
    course.home_wiki.project = homeWikiProject;
    return this.props.updateCourse(course);
  },

  render() {
    const options = JSON.parse(WikiProjects).map((project, index) => {
      return (<option value={project} key={index}>{project}</option>);
    });

    const selector = (
      <div className="form-group">
        <label htmlFor={this.state.id}>{I18n.t('courses.home_wiki_project')}:</label>
        <select
          id={this.state.id}
          name="home_wiki_project"
          value={this.props.course.home_wiki.project}
          onChange={this._handleChange}
        >
          {options}
        </select>
      </div>
    );

    return (
      <div className="home_wiki_project_selector">
        {selector}
      </div>
    );
  }
});

export default HomeWikiProjectSelector;

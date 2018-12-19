import React from 'react';
import createReactClass from 'create-react-class';
import PropTypes from 'prop-types';
import Select from 'react-select';
import uuid from 'uuid';
import selectStyles from '../../styles/single_select';

const HomeWikiProjectSelector = createReactClass({
  propTypes: {
    course: PropTypes.object,
    updateCourse: PropTypes.func.isRequired
  },

  componentWillMount() {
    this.setState({
      id: uuid.v4(),
      selectedOption: { value: this.props.course.home_wiki.project, label: this.props.course.home_wiki.project },
    });
  },

  _handleChange(selectedOption) {
    const course = this.props.course;
    const homeWikiProject = selectedOption.value;
    course.home_wiki.project = homeWikiProject;
    this.setState({ selectedOption });
    return this.props.updateCourse(course);
  },

  render() {
    const options = JSON.parse(WikiProjects).map((project) => {
     return { value: project, label: project };
    });
    const selector = (
      <div className="form-group">
        <label htmlFor={this.state.id}>{I18n.t('courses.home_wiki_project')}:</label>
        <Select
          id={this.state.id}
          value={this.state.selectedOption}
          onChange={this._handleChange}
          options={options}
          simpleValue
          styles={selectStyles}
        />
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

import React from 'react';
import createReactClass from 'create-react-class';
import PropTypes from 'prop-types';
import CourseLink from './common/course_link';

const CourseAlert = createReactClass({
  displayName: 'CourseAlert',

  propTypes: {
    actionMessage: PropTypes.string,
    actionClassName: PropTypes.string,
    buttonLink: PropTypes.string,
    components: PropTypes.node,
    className: PropTypes.string,
    courseLink: PropTypes.string,
    message: PropTypes.string.isRequired,
    onClick: PropTypes.func
  },
  render() {
    let components = null;
    let action = null;

    if (this.props.components) components = this.props.components;

    if (this.props.actionMessage) {
      action = <a className="button">{this.props.actionMessage}</a>;

      const props = {};
      // Changes type of link to CourseLink and adds link to course
      if (this.props.courseLink) action = <CourseLink to={this.props.courseLink}>{this.props.actionMessage}</CourseLink>;
      // or adds regular button link
      else if (this.props.buttonLink) props.href = this.props.buttonLink;

      // Appends custom class names
      props.className = `button ${this.props.actionClassName}`.trim();
      // Appends onClick if present
      if (this.props.onClick) props.onClick = this.props.onClick;
      action = React.cloneElement(action, props);
    }
    return (
      <div className={this.props.className ? `${this.props.className} notification` : 'notification'}>
        <div className="container">
          <p>{this.props.message}</p>
          {action}
          {components}
        </div>
      </div>
    );
  }
});

export default CourseAlert;

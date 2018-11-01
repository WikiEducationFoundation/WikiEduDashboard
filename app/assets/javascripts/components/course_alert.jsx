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
    onClick: PropTypes.func
  },
  render() {
    const message = I18n.t(this.props.children) === `[missing "${I18n.locale}.${this.props.children}" translation]` ? this.props.children : I18n.t(this.props.children);

    let components = null;
    let action = null;

    if (this.props.components) components = this.props.components;

    if (this.props.actionMessage) {
      const actionMessage = I18n.t(this.props.actionMessage) === `[missing "${I18n.locale}.${this.props.actionMessage}" translation]` ? this.props.actionMessage : I18n.t(this.props.actionMessage);

      action = <a className="button">{actionMessage}</a>;
      const props = {};
      // Changes type of link to CourseLink and adds link to course
      if (this.props.courseLink) action = <CourseLink classname="button" to={this.props.courseLink}>{actionMessage}</CourseLink>;
      // or adds regular button link
      else if (this.props.buttonLink) props.href = this.props.buttonLink;

      // Appends custom class names
      if (this.props.actionClassName) props.className = `button ${this.props.actionClassName}`;
      // Appends onClick if present
      if (this.props.onClick) props.onClick = this.props.onClick;
      action = React.cloneElement(action, props);
    }
    return (
      <div className={this.props.className ? `${this.props.className} notification` : 'notification'}>
        <div className="container">
          <p>{message}</p>
          {action}
          {components}
        </div>
      </div>
    );
  }
});

export default CourseAlert;

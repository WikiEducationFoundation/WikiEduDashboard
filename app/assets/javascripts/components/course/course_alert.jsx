import React from 'react';
import PropTypes from 'prop-types';
import CourseLink from '../common/course_link';

const CourseAlert = (props) => {
  let componentsElement = null;
  let action = null;

  if (props.components) componentsElement = props.components;

  if (props.actionMessage) {
    action = <a href={props.href || '#'} className="button">{props.actionMessage}</a>;

    const propsElement = {};
    // Changes type of link to CourseLink and adds link to course
    if (props.courseLink) {
      action = <CourseLink to={props.courseLink}>{props.actionMessage}</CourseLink>;
    } else if (props.buttonLink) {
      propsElement.href = props.buttonLink;
    }

    // Appends custom class names
    propsElement.className = `button ${props.actionClassName}`.trim();
    // Appends onClick if present
    if (props.onClick) propsElement.onClick = props.onClick;
    action = React.cloneElement(action, propsElement);
  }

  const messages = [].concat(props.message);

  return (
    <div className={props.className ? `${props.className} notification` : 'notification'}>
      <div className="container">
        {messages.map((msg, i) => <p key={i}>{msg}</p>)}
        {action}
        {componentsElement}
      </div>
    </div>
  );
};

CourseAlert.propTypes = {
  actionMessage: PropTypes.string,
  actionClassName: PropTypes.string,
  buttonLink: PropTypes.string,
  components: PropTypes.node,
  className: PropTypes.string,
  courseLink: PropTypes.string,
  href: PropTypes.string,
  message: PropTypes.any,
  onClick: PropTypes.func
};

export default CourseAlert;

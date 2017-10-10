import React from 'react';
import createReactClass from 'create-react-class';
import PropTypes from 'prop-types';
import ServerActions from '../../actions/server_actions.js';

const GreetStudentsButton = createReactClass({
  propTypes: {
    course: PropTypes.object,
    current_user: PropTypes.object
  },

  greetStudents() {
    ServerActions.greetStudents(this.props.course.id);
  },

  render() {
    // Render nothing if user isn't an admin, or it's not the Wiki Ed Dashboard
    if (!this.props.current_user.admin || !Features.wikiEd) {
      return <div />;
    }

    return (
      <p key="greet_students"><button onClick={this.greetStudents} className="button">Greet students</button></p>
    );
  }
});

export default GreetStudentsButton;

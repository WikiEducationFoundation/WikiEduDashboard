import React from 'react';
import ServerActions from '../../actions/server_actions.js';

const GreetStudentsButton = React.createClass({
  propTypes: {
    course: React.PropTypes.object,
    current_user: React.PropTypes.object
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

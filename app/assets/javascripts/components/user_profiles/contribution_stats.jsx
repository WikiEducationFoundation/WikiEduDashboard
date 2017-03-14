import React from 'react';
import InstructorStats from './instructor_stats.jsx';
import StudentStats from './student_stats.jsx';
import ByStudents from './by_students.jsx';
import ProfileStore from '../../stores/profile_store.js';
import ProfileActions from '../../actions/profile_actions.js';

const getState = function () {
  const isstudent = $('#react_root').data('isstudent');
  const isinstructor = $('#react_root').data('isinstructor');
  let selectedLink;
  if (!isinstructor.instructor) {
    selectedLink = 'student_stats';
  }
  else {
    selectedLink = 'instructor_stats';
  }
  return {
    isstudent: isstudent,
    isinstructor: isinstructor,
    selectedLink: selectedLink,
    stats: ProfileStore.getStats()
  };
};
const ContributionStats = React.createClass({
  propTypes: {
    params: React.PropTypes.object
  },

  mixins: [ProfileStore.mixin], // adding store eventing to the component

  getInitialState() {
    return getState();
  },

  componentDidMount() {
    ProfileActions.fetch_stats(this.props.params.username);
  },

  setInstructor() {
    this.setState({
      selectedLink: 'instructor_stats'
    });
  },
  setStudent() {
    this.setState({
      selectedLink: 'student_stats'
    });
  },
  setByStudents() {
    this.setState({
      selectedLink: 'bystudents_stats'
    });
  },
  storeDidChange() {
    this.setState(
      {
        stats: ProfileStore.getStats()
      }
    );
  },
  render() {
    console.log('store_data');
    console.log(this.state.stats);
    let contriStats;
    let navElements;
    let statistics;

    if (this.state.selectedLink === 'instructor_stats')
    {
      contriStats = <InstructorStats />;
    }
    else if (this.state.selectedLink === 'student_stats') {
      contriStats = <StudentStats />;
    }
    else if (this.state.selectedLink === 'bystudents_stats') {
      contriStats = <ByStudents />;
    }


    if (this.state.isstudent.student || this.state.isinstructor.instructor)
    {
      if (this.state.isstudent.student && this.state.isinstructor.instructor) {
        navElements = (
          <ul className = "top-nav__main-links">
            <li>
              <button onClick={this.setInstructor} className="button dark">As an Instructor</button>
            </li>
            <li>
              <button onClick={this.setStudent} className="button dark">As a student</button>
            </li>
            <li>
              <button onClick={this.setByStudents} className="button dark">By his/her students</button>
            </li>
          </ul>
        );
      }
      else if (this.state.isstudent.student) {
        navElements = (
          <ul className = "top-nav__main-links">
            <li>
              <button onClick={this.setStudent} className="button dark">As a student</button>
            </li>
          </ul>
        );
      }
      else if (this.state.isinstructor.instructor) {
        navElements = (
          <ul className = "top-nav__main-links">
            <li>
              <button onClick={this.setInstructor} className="button dark">As an Instructor</button>
            </li>
            <li>
              <button onClick={this.setByStudents} className="button dark">By his/her students</button>
            </li>
          </ul>
        );
      }

      statistics = (
        <div>
          <div id = "react-profile">
            <div id = "react-info">
              <h4>
                Total Impact made by { this.props.params.username }
              </h4>
            </div>
            <div id = "react-nav">
              <nav className ="profile-nav">
                {navElements}
              </nav>
            </div>
          </div>
          {contriStats}
        </div>
      );
    }

    return (
      <div>
        { statistics }
      </div>
    );
  }
});

export default ContributionStats;

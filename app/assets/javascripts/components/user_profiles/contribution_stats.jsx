import React from 'react';
import InstructorStats from './instructor_stats.jsx';
import StudentStats from './student_stats.jsx';
import ByStudents from './by_students.jsx';
import ProfileStore from '../../stores/profile_store.js';

const ContributionStats = React.createClass({
  propTypes: {
    params: React.PropTypes.object
  },

  // const studentdataUrl = `/users/stats_data.json?username=${ this.props.params.username }`;
  // ProfileActions.fetch_stats(userId)
  // getState() function in the stats component to fetch data from the profile store,
  //  have the store implement .getLoadingStatus() so as to render a loading spinner
  //  before the data arrives.
  mixins: [ProfileStore.mixin],

  getInitialState() {
    return {
      selectedLink: 'instructor_stats',
    };
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
  render() {
    console.log(this.props);
    let contriStats;

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

    return (
      <div>
        <div id = "react-profile">
          <div id = "react-info">
            <h4>
              Total Impact made by { this.props.params.username }
            </h4>
          </div>
          <div id = "react-nav">
            <nav className ="profile-nav">
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
            </nav>
          </div>
        </div>
        {contriStats}
      </div>
    );
  }
});

export default ContributionStats;

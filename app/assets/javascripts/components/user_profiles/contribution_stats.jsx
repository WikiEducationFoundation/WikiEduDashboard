import React from 'react';
import InstructorStats from './instructor_stats.jsx';
import StudentStats from './student_stats.jsx';
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
    if (this.state.isinstructor.instructor) {
      contriStats = <InstructorStats />;
    }
    else if (this.state.isstudent.student) {
      contriStats = <StudentStats />;
    }
    return (
      <div>
        {contriStats}
      </div>
    );
  }
});

export default ContributionStats;

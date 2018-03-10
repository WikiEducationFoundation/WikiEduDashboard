import React from 'react';
import { connect } from "react-redux";
import createReactClass from 'create-react-class';
import PropTypes from 'prop-types';
import CourseStats from './course_stats.jsx';
import AvailableActions from './available_actions.jsx';
import Description from './description.jsx';
import Milestones from './milestones.jsx';
import Details from './details.jsx';
import ThisWeek from './this_week.jsx';
import CourseStore from '../../stores/course_store.js';
import AssignmentStore from '../../stores/assignment_store.js';
import WeekStore from '../../stores/week_store.js';
import ServerActions from '../../actions/server_actions.js';
import CourseActions from '../../actions/course_actions.js';
import Loading from '../common/loading.jsx';
import CourseClonedModal from './course_cloned_modal.jsx';
import SyllabusUpload from './syllabus-upload.jsx';
import MyArticles from './my_articles.jsx';
import Modal from '../common/modal.jsx';
import StatisticsUpdateInfo from './statistics_update_info.jsx';
import { getStudentUsers } from '../../selectors';

const getState = () =>
  ({
    course: CourseStore.getCourse(),
    loading: WeekStore.getLoadingStatus(),
    weeks: WeekStore.getWeeks(),
    current: CourseStore.getCurrentWeek()
  })
;

const POLL_INTERVAL = 300000; // 5 minutes

const Overview = createReactClass({
  displayName: 'Overview',

  propTypes: {
    current_user: PropTypes.object,
    course_id: PropTypes.string,
    location: PropTypes.object,
    students: PropTypes.array
  },

  mixins: [WeekStore.mixin, CourseStore.mixin, AssignmentStore.mixin],

  getInitialState() {
    return getState();
  },

  componentDidMount() {
    ServerActions.fetch('timeline', this.props.course_id);
    return ServerActions.fetch('tags', this.props.course_id);
  },

  componentWillUnmount() {
    clearInterval(this.timeout);
  },

  storeDidChange() {
    return this.setState(getState());
  },

  timeout: setInterval(() => CourseActions.updateCourse(), POLL_INTERVAL),

  render() {
    if (this.state.course.cloned_status === 1) {
      return (
        <CourseClonedModal
          course={this.state.course}
          updateCourse={this.updateCourse}
          valuesUpdated={this.state.valuesUpdated}
        />
      );
    }

    let syllabusUpload;
    if (this.props.location.query.syllabus_upload === 'true' && this.props.current_user.admin) {
      syllabusUpload = (
        <Modal modalClass="course__syllabus-upload">
          <SyllabusUpload {...this.props} />
        </Modal>
      );
    }

    let thisWeek;
    const noWeeks = !this.state.weeks || this.state.weeks.length === 0;
    if (!this.state.course.legacy && !noWeeks) {
      thisWeek = (
        <ThisWeek
          course={this.state.course}
          weeks={this.state.weeks}
          current={this.state.current}
        />
      );
    }

    const primaryContent = this.state.loading ? (
      <Loading />
    ) : (
      <div>
        <Description {...this.props} />
        {thisWeek}
      </div>
    );

    let userArticles;
    if (this.props.current_user.isStudent && this.state.course.id) {
      userArticles = (
        <MyArticles
          course={this.state.course}
          course_id={this.props.course_id}
          current_user={this.props.current_user}
        />
      );
    }

    const sidebar = this.state.course.id ? (
      <div className="sidebar">
        <Details {...this.props} />
        <AvailableActions {...this.props} />
        <Milestones {...this.props} />
      </div>
    ) : (
      <div className="sidebar" />
    );

    return (
      <section className="overview container">
        { syllabusUpload }
        <h3 className="tooltip-trigger">{I18n.t('metrics.label')}
        </h3>
        <CourseStats course={this.state.course} />
        <StatisticsUpdateInfo course={this.state.course} />
        {userArticles}
        <div className="primary">
          {primaryContent}
        </div>
        {sidebar}
      </section>
    );
  }
}
);

const mapStateToProps = state => ({
  students: getStudentUsers(state),
  campaigns: state.campaigns.campaigns
 });


export default connect(mapStateToProps)(Overview);

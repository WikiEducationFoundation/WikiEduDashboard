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
import Loading from '../common/loading.jsx';
import CourseClonedModal from './course_cloned_modal.jsx';
import SyllabusUpload from './syllabus-upload.jsx';
import MyArticles from './my_articles.jsx';
import Modal from '../common/modal.jsx';
import StatisticsUpdateInfo from './statistics_update_info.jsx';
import ServerActions from '../../actions/server_actions.js';
import { getStudentUsers } from '../../selectors';

const getState = () =>
  ({
    course: CourseStore.getCourse(),
    loading: WeekStore.getLoadingStatus(),
    weeks: WeekStore.getWeeks()
  })
;

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

  storeDidChange() {
    return this.setState(getState());
  },

  render() {
    const course = this.state.course;
    if (course.cloned_status === 1) {
      return <CourseClonedModal course={course} />;
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
    if (!course.legacy && !noWeeks) {
      thisWeek = (
        <ThisWeek
          course={course}
          weeks={this.state.weeks}
        />
      );
    }

    const primaryContent = this.state.loading ? (
      <Loading />
    ) : (
      <div>
        <Description
          description={course.description}
          title={course.title}
          course_id={this.props.course_id}
          current_user={this.props.current_user}
        />
        {thisWeek}
      </div>
    );

    let userArticles;
    if (this.props.current_user.isStudent && course.id) {
      userArticles = (
        <MyArticles
          course={course}
          course_id={this.props.course_id}
          current_user={this.props.current_user}
        />
      );
    }

    const sidebar = course.id ? (
      <div className="sidebar">
        <Details {...this.props} />
        <AvailableActions course={course} current_user={this.props.current_user} />
        <Milestones timelineStart={course.timeline_start} weeks={this.state.weeks} />
      </div>
    ) : (
      <div className="sidebar" />
    );

    return (
      <section className="overview container">
        { syllabusUpload }
        <h3 className="tooltip-trigger">{I18n.t('metrics.label')}
        </h3>
        <CourseStats course={course} />
        <StatisticsUpdateInfo course={course} />
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

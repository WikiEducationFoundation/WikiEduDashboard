import React from 'react';
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
import UserStore from '../../stores/user_store.js';
import UserUtils from '../../utils/user_utils.js';
import WeekStore from '../../stores/week_store.js';
import ServerActions from '../../actions/server_actions.js';
import Loading from '../common/loading.jsx';
import CourseClonedModal from './course_cloned_modal.jsx';
import SyllabusUpload from './syllabus-upload.jsx';
import MyArticles from './my_articles.jsx';
import Modal from '../common/modal.jsx';

const getState = () =>
  ({
    course: CourseStore.getCourse(),
    loading: WeekStore.getLoadingStatus(),
    weeks: WeekStore.getWeeks(),
    current: CourseStore.getCurrentWeek()
  })
;

const Overview = createReactClass({
  displayName: 'Overview',

  propTypes: {
    current_user: PropTypes.object,
    course_id: PropTypes.string,
    location: PropTypes.object
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
    const userRoles = UserUtils.userRoles(this.props.current_user, UserStore);

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
    if (userRoles.isStudent && this.state.course.id) {
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

    let courseStatistics;
    if (!this.state.course.ended && !Features.wikiEd) {
      courseStatistics = (
        <div className="pull-right">
          <small>{I18n.t('metrics.are_updated')}. {I18n.t('metrics.last_update')}: {this.state.course.last_update ? moment(this.state.course.last_update).fromNow() : '-'}</small>
        </div>
      );
    }

    return (
      <section className="overview container">
        { syllabusUpload }
        <CourseStats course={this.state.course} />
        {courseStatistics}
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

export default Overview;

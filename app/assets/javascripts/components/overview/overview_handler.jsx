import React from 'react';
import AvailableActions from './available_actions.jsx';
import Description from './description.jsx';
import Milestones from './milestones.jsx';
import Details from './details.jsx';
import ThisWeek from './this_week.jsx';
import CourseStore from '../../stores/course_store.coffee';
import AssignmentStore from '../../stores/assignment_store.js';
import WeekStore from '../../stores/week_store.coffee';
import ServerActions from '../../actions/server_actions.js';
import Loading from '../common/loading.jsx';
import CourseClonedModal from './course_cloned_modal.cjsx';
import CourseUtils from '../../utils/course_utils.js';
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

const Overview = React.createClass({
  displayName: 'Overview',

  propTypes: {
    current_user: React.PropTypes.object,
    course_id: React.PropTypes.string,
    location: React.PropTypes.object
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
    if (this.props.location.query.modal === 'true' && this.state.course.id) {
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

    let primaryContent = this.state.loading ? (
      <Loading />
    ) : (
      <div>
        <Description {...this.props} />
        {thisWeek}
      </div>
    );

    let userArticles;
    if (this.props.current_user.role === 0 && this.state.course.id) {
      userArticles = (
        <MyArticles
          course={this.state.course}
          course_id={this.props.course_id}
          current_user={this.props.current_user}
        />
      );
    }

    let sidebar = this.state.course.id ? (
      <div className="sidebar">
        {userArticles}
        <Details {...this.props} />
        <AvailableActions {...this.props} />
        <Milestones {...this.props} />
      </div>
    ) : (
      <div className="sidebar">
      </div>
    );

    return (
      <section className="overview container">
        { syllabusUpload }
        <div className="stat-display">
          <div className="stat-display__stat" id="articles-created">
            <div className="stat-display__value">{this.state.course.created_count}</div>
            <small>{I18n.t('metrics.articles_created')}</small>
          </div>
          <div className="stat-display__stat" id="articles-edited">
            <div className="stat-display__value">{this.state.course.edited_count}</div>
            <small>{I18n.t('metrics.articles_edited')}</small>
          </div>
          <div className="stat-display__stat" id="total-edits">
            <div className="stat-display__value">{this.state.course.edit_count}</div>
            <small>{I18n.t('metrics.edit_count_description')}</small>
          </div>
          <div className="stat-display__stat tooltip-trigger" id="student-editors">
            <div className="stat-display__value">{this.state.course.student_count}</div>
            <small>{CourseUtils.i18n('student_editors', this.state.course.string_prefix)}</small>
            <div className="tooltip dark" id="trained-count">
              <h4 className="stat-display__value">{this.state.course.trained_count}</h4>
              <p>{I18n.t('metrics.are_trained')}</p>
            </div>
          </div>
          <div className="stat-display__stat" id="word-count">
            <div className="stat-display__value">{this.state.course.word_count}</div>
            <small>{I18n.t('metrics.word_count')}</small>
          </div>
          <div className="stat-display__stat" id="view-count">
            <div className="stat-display__value">{this.state.course.view_count}</div>
            <small>{I18n.t('metrics.view_count_description')}</small>
          </div>
        </div>
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

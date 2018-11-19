import React from 'react';
import { connect } from 'react-redux';
import createReactClass from 'create-react-class';
import PropTypes from 'prop-types';
import CourseStats from './course_stats.jsx';
import AvailableActions from './available_actions.jsx';
import Description from './description.jsx';
import Milestones from './milestones.jsx';
import Details from './details.jsx';
import ThisWeek from './this_week.jsx';
import Loading from '../common/loading.jsx';
import CourseClonedModal from './course_cloned_modal.jsx';
import SyllabusUpload from './syllabus-upload.jsx';
import MyArticles from './my_articles.jsx';
import Modal from '../common/modal.jsx';
import StatisticsUpdateInfo from './statistics_update_info.jsx';
import { updateCourse, resetCourse, persistCourse, nameHasChanged, updateClonedCourse, refetchCourse } from '../../actions/course_actions';
import { fetchTags } from '../../actions/tag_actions';
import { setValid, setInvalid, activateValidations } from '../../actions/validation_actions';
import { getStudentUsers, getWeeksArray, firstValidationErrorMessage, isValid } from '../../selectors';

const Overview = createReactClass({
  displayName: 'Overview',

  propTypes: {
    course: PropTypes.object.isRequired,
    current_user: PropTypes.object,
    course_id: PropTypes.string,
    location: PropTypes.object,
    students: PropTypes.array,
    fetchTags: PropTypes.func.isRequired,
    updateCourse: PropTypes.func.isRequired,
    resetCourse: PropTypes.func.isRequired,
    updateClonedCourse: PropTypes.func.isRequired,
    weeks: PropTypes.array.isRequired,
    setValid: PropTypes.func.isRequired,
    setInvalid: PropTypes.func.isRequired,
    activateValidations: PropTypes.func.isRequired,
    firstErrorMessage: PropTypes.string,
    isValid: PropTypes.bool.isRequired
  },

  componentDidMount() {
    if (this.props.current_user.admin) {
      this.props.fetchTags(this.props.course_id);
    }
  },

  render() {
    const course = this.props.course;
    if (course.cloned_status === 1) {
      return (
        <CourseClonedModal
          course={course}
          updateCourse={this.props.updateCourse}
          updateClonedCourse={this.props.updateClonedCourse}
          currentUser={this.props.current_user}
          firstErrorMessage={this.props.firstErrorMessage}
          isValid={this.props.isValid}
          setValid={this.props.setValid}
          setInvalid={this.props.setInvalid}
          activateValidations={this.props.activateValidations}
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
    const noWeeks = this.props.weeks.length === 0;
    if (!course.legacy && !noWeeks) {
      thisWeek = (
        <ThisWeek
          course={course}
          weeks={this.props.weeks}
        />
      );
    }

    const primaryContent = this.props.loading ? (
      <Loading />
    ) : (
      <div>
        <Description
          description={course.description}
          title={course.title}
          course_id={this.props.course_id}
          current_user={this.props.current_user}
          updateCourse={this.props.updateCourse}
          resetState={this.props.resetCourse}
          persistCourse={this.props.persistCourse}
          nameHasChanged={this.props.nameHasChanged}
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
        <Details
          {...this.props}
          updateCourse={this.props.updateCourse}
          resetState={this.props.resetCourse}
          persistCourse={this.props.persistCourse}
          nameHasChanged={this.props.nameHasChanged}
          refetchCourse={this.props.refetchCourse}
        />
        <AvailableActions course={course} current_user={this.props.current_user} updateCourse={this.props.updateCourse} />
        <Milestones timelineStart={course.timeline_start} weeks={this.props.weeks} />
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
  campaigns: state.campaigns.campaigns,
  weeks: getWeeksArray(state),
  loading: state.timeline.loading,
  firstErrorMessage: firstValidationErrorMessage(state),
  isValid: isValid(state)
 });

const mapDispatchToProps = {
  updateCourse,
  resetCourse,
  persistCourse,
  nameHasChanged,
  updateClonedCourse,
  fetchTags,
  refetchCourse,
  setValid,
  setInvalid,
  activateValidations
};


export default connect(mapStateToProps, mapDispatchToProps)(Overview);

import React from 'react';
import { connect } from 'react-redux';
import createReactClass from 'create-react-class';
import PropTypes from 'prop-types';
import { parse } from 'query-string';
import withRouter from '../util/withRouter';
import OverviewStats from './overview_stats.jsx';
import AvailableActions from './available_actions.jsx';
import Description from './description.jsx';
import Milestones from './milestones.jsx';
import Details from './details.jsx';
import ThisWeek from './this_week.jsx';
import Loading from '../common/loading.jsx';
import CourseClonedModal from './course_cloned_modal.jsx';
import SyllabusUpload from './syllabus-upload.jsx';
import AdminQuickActions from './admin_quick_actions.jsx';
import MyArticles from './my_articles/containers';
import MyExercises from './my_exercises/containers/Container';
import Modal from '../common/modal.jsx';
import StatisticsUpdateInfo from './statistics_update_info.jsx';
import { initiateConfirm } from '../../actions/confirm_actions.js';
import { deleteCourse, updateCourse, resetCourse, persistCourse, nameHasChanged, updateClonedCourse, refetchCourse, greetStudents } from '../../actions/course_actions';
import { fetchOnboardingAlert } from '../../actions/course_alert_actions';
import { fetchTags } from '../../actions/tag_actions';
import { addValidation, setValid, setInvalid, activateValidations } from '../../actions/validation_actions';
import { getStudentUsers, getWeeksArray, getAllWeeksArray, firstValidationErrorMessage, isValid } from '../../selectors';
import OverviewStatsTabs from '../common/overview_stats_tabs';

const Overview = createReactClass({
  displayName: 'Overview',

  propTypes: {
    course: PropTypes.object.isRequired,
    current_user: PropTypes.object,
    course_id: PropTypes.string,
    location: PropTypes.object,
    students: PropTypes.array,
    initiateConfirm: PropTypes.func.isRequired,
    deleteCourse: PropTypes.func.isRequired,
    fetchTags: PropTypes.func.isRequired,
    fetchOnboardingAlert: PropTypes.func.isRequired,
    updateCourse: PropTypes.func.isRequired,
    resetCourse: PropTypes.func.isRequired,
    updateClonedCourse: PropTypes.func.isRequired,
    weeks: PropTypes.array.isRequired,
    allWeeks: PropTypes.array.isRequired,
    setValid: PropTypes.func.isRequired,
    setInvalid: PropTypes.func.isRequired,
    activateValidations: PropTypes.func.isRequired,
    firstErrorMessage: PropTypes.string,
    isValid: PropTypes.bool.isRequired,
    courseCreationNotice: PropTypes.string,
    allWeekDates: PropTypes.array,
  },

  componentDidMount() {
    document.title = this.props.course.title;
    if (this.props.current_user.admin) {
      this.props.fetchOnboardingAlert(this.props.course);
      this.props.fetchTags(this.props.course_id);
    }
  },

  render() {
    const { course, current_user } = this.props;

    if (course.cloned_status === 1 || course.cloned_status === 3) {
      return (
        <CourseClonedModal
          course={course}
          initiateConfirm={this.props.initiateConfirm}
          deleteCourse={this.props.deleteCourse}
          updateCourse={this.props.updateCourse}
          updateClonedCourse={this.props.updateClonedCourse}
          currentUser={this.props.current_user}
          firstErrorMessage={this.props.firstErrorMessage}
          isValid={this.props.isValid}
          setValid={this.props.setValid}
          setInvalid={this.props.setInvalid}
          addValidation={this.props.addValidation}
          activateValidations={this.props.activateValidations}
          courseCreationNotice={this.props.courseCreationNotice}
        />
      );
    }

    let syllabusUpload;
    const query = parse(this.props.router.location.search);
    if (query.syllabus_upload === 'true' && this.props.current_user.admin) {
      syllabusUpload = (
        <Modal modalClass="course__syllabus-upload">
          <SyllabusUpload course={this.props.course} />
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
          current_user={this.props.current_user}
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
    // const isWikidataCourse = course.home_wiki && course.home_wiki.project === 'wikidata';
    if (this.props.current_user.isEnrolled && course.id) {
      userArticles = (
        <>
          <MyExercises trainingLibrarySlug={this.props.course.training_library_slug} />
          <MyArticles
            course={course}
            course_id={this.props.course_id}
            current_user={this.props.current_user}
          />
        </>
      );
    }

    const sidebar = course.id ? (
      <div className="sidebar">
        {
          Features.wikiEd && current_user.admin && (
            <AdminQuickActions
              course={course}
              current_user={current_user}
              persistCourse={this.props.persistCourse}
              greetStudents={this.props.greetStudents}
            />
          )
        }
        <Details
          {...this.props}
          updateCourse={this.props.updateCourse}
          resetState={this.props.resetCourse}
          persistCourse={this.props.persistCourse}
          nameHasChanged={this.props.nameHasChanged}
          refetchCourse={this.props.refetchCourse}
        />
        <AvailableActions course={course} current_user={this.props.current_user} updateCourse={this.props.updateCourse} courseCreationNotice={this.props.courseCreationNotice} />
        <Milestones timelineStart={course.timeline_start} timelineEnd={course.timeline_end} weeks={this.props.weeks} allWeeks={this.props.allWeeks} course={course} weekDates={this.props.allWeekDates} />
      </div>
    ) : (
      <div className="sidebar" />
    );

    let overviewStatsTabs;
    if (course.course_stats && course.course_stats.stats_hash) {
      overviewStatsTabs = <OverviewStatsTabs course={course} statistics={course.course_stats.stats_hash} />;
    }

    return (
      <section className="overview container">
        {syllabusUpload}
        <OverviewStats course={course} />
        {overviewStatsTabs}
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
  allWeeks: getAllWeeksArray(state),
  loading: state.timeline.loading || state.course.loading,
  firstErrorMessage: firstValidationErrorMessage(state),
  isValid: isValid(state),
  courseCreationNotice: state.courseCreator.courseCreationNotice
});

const mapDispatchToProps = {
  initiateConfirm,
  deleteCourse,
  updateCourse,
  resetCourse,
  persistCourse,
  nameHasChanged,
  updateClonedCourse,
  fetchTags,
  refetchCourse,
  addValidation,
  setValid,
  setInvalid,
  activateValidations,
  fetchOnboardingAlert,
  greetStudents
};


export default withRouter(connect(mapStateToProps, mapDispatchToProps)(Overview));

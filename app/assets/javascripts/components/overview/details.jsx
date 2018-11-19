import React from 'react';
import createReactClass from 'create-react-class';
import PropTypes from 'prop-types';

import Instructors from './instructors';
import OnlineVolunteers from './online_volunteers';
import CampusVolunteers from './campus_volunteers';
import WikiEdStaff from './wiki_ed_staff';

import CampaignEditable from './campaign_editable.jsx';
import CampaignList from './campaign_list.jsx';
import TagList from './tag_list.jsx';
import TagEditable from './tag_editable';
import CourseTypeSelector from './course_type_selector.jsx';
import SubmittedSelector from './submitted_selector.jsx';
import PrivacySelector from './privacy_selector.jsx';
import WithdrawnSelector from './withdrawn_selector.jsx';
import TimelineToggle from './timeline_toggle.jsx';
import WikiEditsToggle from './wiki_edits_toggle';
import CourseLevelSelector from '../course_creator/course_level_selector.jsx';
import HomeWikiProjectSelector from './home_wiki_project_selector.jsx';
import HomeWikiLanguageSelector from './home_wiki_language_selector.jsx';
import Modal from '../common/modal.jsx';

import EditableRedux from '../high_order/editable_redux.jsx';
import TextInput from '../common/text_input.jsx';
import Notifications from '../common/notifications.jsx';

import DatePicker from '../common/date_picker.jsx';

import CourseUtils from '../../utils/course_utils.js';
import CourseDateUtils from '../../utils/course_date_utils.js';

const POLL_INTERVAL = 60000; // 1 minute

const Details = createReactClass({
  displayName: 'Details',

  propTypes: {
    course: PropTypes.object,
    current_user: PropTypes.object,
    campaigns: PropTypes.array,
    controls: PropTypes.func,
    editable: PropTypes.bool,
    updateCourse: PropTypes.func.isRequired,
    refetchCourse: PropTypes.func.isRequired,
    firstErrorMessage: PropTypes.string
  },

  componentDidMount() {
    this.timeout = this.poll(); // Start polling
  },

  componentWillUnmount() {
    if (this.timeout) {
      clearInterval(this.timeout); // End it
    }
  },
  updateDetails(valueKey, value) {
    const updatedCourse = this.props.course;
    updatedCourse[valueKey] = value;
    return this.props.updateCourse(updatedCourse);
  },

  updateSlugPart(valueKey, value) {
    const updatedCourse = this.props.course;
    updatedCourse[valueKey] = value;
    updatedCourse.slug = CourseUtils.generateTempId(updatedCourse);
    return this.props.updateCourse(updatedCourse);
  },

  updateCourseDates(valueKey, value) {
    const updatedCourse = CourseDateUtils.updateCourseDates(this.props.course, valueKey, value);
    return this.props.updateCourse(updatedCourse);
  },

  canRename() {
    if (!this.props.editable) { return false; }
    if (this.props.current_user.admin) { return true; }
    // On the Wiki Ed dashboard, only admins may rename courses.
    if (Features.wikiEd) { return false; }
    // On P&E Dashboard, anyone with edit rights for the course may rename it.
    return true;
  },

  poll() {
    return setInterval(() => {
      if (!this.props.editable) {
        this.props.refetchCourse(this.props.course.slug);
      }
    }, POLL_INTERVAL);
  },

  timeout: null,

  render() {
    const canRename = this.canRename();
    const isClassroomProgramType = this.props.course.type === 'ClassroomProgramCourse';
    const timelineDatesDiffer = this.props.course.start !== this.props.course.timeline_start || this.props.course.end !== this.props.course.timeline_end;
    let online;
    let campus;
    let staff;
    let school;
    if (Features.wikiEd) {
      staff = <WikiEdStaff {...this.props} />;
      online = <OnlineVolunteers {...this.props} />;
      campus = <CampusVolunteers {...this.props} />;
    }

    if (this.props.course.school || canRename) {
      school = (
        <TextInput
          onChange={this.updateSlugPart}
          value={this.props.course.school}
          value_key="school"
          validation={CourseUtils.courseSlugRegex()}
          editable={canRename}
          type="text"
          label={CourseUtils.i18n('school', this.props.course.string_prefix)}
          required={true}
        />
      );
    }

    let title;
    if (canRename) {
      title = (
        <TextInput
          onChange={this.updateSlugPart}
          value={this.props.course.title}
          value_key="title"
          validation={CourseUtils.courseSlugRegex()}
          editable={canRename}
          type="text"
          label={CourseUtils.i18n('title', this.props.course.string_prefix)}
          required={true}
        />
      );
    }

    let term;
    if (this.props.course.term || canRename) {
      term = (
        <TextInput
          onChange={this.updateSlugPart}
          value={this.props.course.term}
          value_key="term"
          validation={CourseUtils.courseSlugRegex()}
          editable={canRename}
          type="text"
          label={CourseUtils.i18n('term', this.props.course.string_prefix)}
          required={false}
        />
      );
    }

    let passcode;
    if (this.props.course.passcode || this.props.editable) {
      passcode = (
        <TextInput
          onChange={this.updateDetails}
          value={this.props.course.passcode}
          value_key="passcode"
          editable={this.props.editable}
          type="text"
          label={I18n.t('courses.passcode')}
          placeholder={I18n.t('courses.passcode_none')}
          required={!!this.props.course.passcode_required}
        />
      );
    }

    let expectedStudents;
    if ((this.props.course.expected_students || this.props.course.expected_students === 0 || this.props.editable) && isClassroomProgramType) {
      expectedStudents = (
        <TextInput
          onChange={this.updateDetails}
          value={String(this.props.course.expected_students)}
          value_key="expected_students"
          editable={this.props.editable}
          type="number"
          label={CourseUtils.i18n('expected_students', this.props.course.string_prefix)}
        />
      );
    }

    const dateProps = CourseDateUtils.dateProps(this.props.course);
    let timelineStart;
    let timelineEnd;
    if (timelineDatesDiffer || this.props.editable) {
      timelineStart = (
        <DatePicker
          onChange={this.updateCourseDates}
          value={this.props.course.timeline_start}
          value_key="timeline_start"
          editable={this.props.editable}
          validation={CourseDateUtils.isDateValid}
          label={CourseUtils.i18n('assignment_start', this.props.course.string_prefix)}
          date_props={dateProps.timeline_start}
          showTime={this.props.course.use_start_and_end_times}
          required={true}
        />
      );
      timelineEnd = (
        <DatePicker
          onChange={this.updateCourseDates}
          value={this.props.course.timeline_end}
          value_key="timeline_end"
          editable={this.props.editable}
          validation={CourseDateUtils.isDateValid}
          label={CourseUtils.i18n('assignment_end', this.props.course.string_prefix)}
          date_props={dateProps.timeline_end}
          showTime={this.props.course.use_start_and_end_times}
          required={true}
        />
      );
    }
    let campaignEditable;
    if (canRename) {
      campaignEditable = <CampaignEditable {...this.props} show={this.props.editable} />;
    }
    const campaigns = (
      <span className="campaigns" id="course_campaigns">
        <CampaignList {...this.props} />
        {campaignEditable}
      </span>
    );
    let subject;
    let tags;
    let courseTypeSelector;
    let submittedSelector;
    let privacySelector;
    let courseLevelSelector;
    let timelineToggle;
    let wikiEditsToggle;
    let withdrawnSelector;
    let projectSelector;
    let languageSelector;
    if (this.props.current_user.admin) {
      subject = (
        <TextInput
          onChange={this.updateDetails}
          value={this.props.course.subject}
          value_key="subject"
          editable={this.props.editable}
          type="text"
          label={I18n.t('courses.subject')}
        />
      );
      tags = (
        <div className="tags">
          <TagList course={this.props.course} />
          <TagEditable {...this.props} show={this.props.editable} />
        </div>
      );
      submittedSelector = (
        <SubmittedSelector
          course={this.props.course}
          editable={this.props.editable}
          updateCourse={this.props.updateCourse}
        />
      );
      withdrawnSelector = (
        <WithdrawnSelector
          course={this.props.course}
          editable={this.props.editable}
          updateCourse={this.props.updateCourse}
        />
      );
    }

    // Users who can rename a course are also allowed to change the type.
    if (canRename) {
      courseTypeSelector = (
        <CourseTypeSelector
          course={this.props.course}
          editable={this.props.editable}
          updateCourse={this.props.updateCourse}
        />
      );
    }

    // Users who can rename a course are also allowed to make it private.
    if (canRename) {
      privacySelector = (
        <PrivacySelector
          course={this.props.course}
          editable={this.props.editable}
          updateCourse={this.props.updateCourse}
        />
      );
    }

    // Users who edit a course are also allowed to change the level.
    if (this.props.editable && isClassroomProgramType) {
      courseLevelSelector = (
        <CourseLevelSelector
          level={this.props.course.level}
          updateCourse={this.updateDetails}
        />
      );
    }

    // Users who can rename a course are also allowed to toggle the timeline on/off.
    if (canRename && !isClassroomProgramType) {
      timelineToggle = (
        <TimelineToggle
          course={this.props.course}
          editable={this.props.editable}
          updateCourse={this.props.updateCourse}
        />
      );
    }

    // Users who can rename a course are also allowed to toggle the wiki edits on/off.
    // But this toggle is only relevant if the home wiki has edits enabled.
    if (canRename && !isClassroomProgramType && this.props.course.home_wiki_edits_enabled) {
      wikiEditsToggle = (
        <WikiEditsToggle
          course={this.props.course}
          editable={this.props.editable}
          updateCourse={this.props.updateCourse}
        />
      );
    }

    if (this.props.editable && !Features.wikiEd) {
      projectSelector = (
        <HomeWikiProjectSelector
          course={this.props.course}
          updateCourse={this.props.updateCourse}
        />
      );
      languageSelector = (
        <HomeWikiLanguageSelector
          course={this.props.course}
          updateCourse={this.props.updateCourse}
        />
      );
    }

    const shared = (
      <div className="module course-details">
        <div className="section-header">
          <h3>{I18n.t('application.details')}</h3>
          {this.props.controls()}
        </div>
        <div className="module__data extra-line-height">
          <Instructors {...this.props} />
          <div className="details-form">
            <div className="group-left">
              {online}
              {campus}
              {staff}
              <div><p className="red">{this.props.firstErrorMessage}</p></div>
              {school}
              {title}
              {term}
              <form>
                {passcode}
                {expectedStudents}
                <DatePicker
                  onChange={this.updateCourseDates}
                  value={this.props.course.start}
                  value_key="start"
                  validation={CourseDateUtils.isDateValid}
                  editable={this.props.editable}
                  label={CourseUtils.i18n('start', this.props.course.string_prefix)}
                  showTime={this.props.course.use_start_and_end_times}
                  required={true}
                />
                <DatePicker
                  onChange={this.updateCourseDates}
                  value={this.props.course.end}
                  value_key="end"
                  editable={this.props.editable}
                  validation={CourseDateUtils.isDateValid}
                  label={CourseUtils.i18n('end', this.props.course.string_prefix)}
                  date_props={dateProps.end}
                  enabled={Boolean(this.props.course.start)}
                  showTime={this.props.course.use_start_and_end_times}
                  required={true}
                />
              </form>
            </div>
            <div className="group-right">
              {timelineStart}
              {timelineEnd}
              {subject}
              {courseLevelSelector}
              {tags}
              {courseTypeSelector}
              {submittedSelector}
              {privacySelector}
              {timelineToggle}
              {wikiEditsToggle}
              {withdrawnSelector}
              {projectSelector}
              {languageSelector}
            </div>
          </div>
          {campaigns}
        </div>
      </div>
    );

    if (!this.props.editable) {
      return (
        <div>
          {shared}
        </div>
      );
    }

    return (
      <div className="modal-course-details">
        <Modal>
          <Notifications />
          {shared}
        </Modal>
      </div>
    );
  }
}
);

export default EditableRedux(Details, I18n.t('editable.edit_details'));

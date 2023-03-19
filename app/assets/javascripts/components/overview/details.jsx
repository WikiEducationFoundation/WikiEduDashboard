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
import OnlineVolunteersToggle from './online_volunteers_toggle.jsx';
import DisableStudentEmailsToggle from './disable_student_emails.jsx';
import StayInSandboxToggle from './stay_in_sandbox_toggle';
import RetainAvailableArticlesToggle from './retain_available_articles_toggle';

import WikiEditsToggle from './wiki_edits_toggle';
import EditSettingsToggle from './edit_settings_toggle';
import CourseLevelSelector from '../course_creator/course_level_selector';
import CourseFormatSelector from '../course_creator/course_format_selector';
import selectStyles from '../../styles/select';
import WikiSelect from '../common/wiki_select.jsx';
import Modal from '../common/modal.jsx';
import NamespaceSelect from '../common/namespace_select.jsx';

import EditableRedux from '../high_order/editable_redux.jsx';
import TextInput from '../common/text_input.jsx';
import Notifications from '../common/notifications.jsx';

import DatePicker from '../common/date_picker.jsx';

import WIKI_OPTIONS from '../../utils/wiki_options';
import CourseUtils from '../../utils/course_utils.js';
import CourseDateUtils from '../../utils/course_date_utils.js';
import AcademicSystem from '../common/academic_system.jsx';



const POLL_INTERVAL = 60000; // 1 minute
const MAX_UPDATE_COUNT = 60 * 12; // 12 hours of updates

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

  getInitialState() {
    return {
      updateCount: 0
    };
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

  handleWikiChange(wiki) {
    const home_wiki = wiki.value;
    // Wiki object needs to be only { language, project }
    // By the following line we omit the id attribute.
    const { id, ...prev_wiki } = this.props.course.home_wiki;
    const wikis = CourseUtils.normalizeWikis([...this.props.course.wikis], home_wiki, prev_wiki);
    this.props.updateCourse({ ...this.props.course, wikis, home_wiki });
  },

  handleMultiWikiChange(wikis) {
    wikis = wikis.map(wiki => wiki.value);
    const home_wiki = {
      language: this.props.course.home_wiki.language || 'www',
      project: this.props.course.home_wiki.project
    };
    wikis = CourseUtils.normalizeWikis(wikis, home_wiki);
    this.props.updateCourse({ ...this.props.course, wikis });
  },

  handleNamespaceChange(namespaces) {
    this.props.updateCourse({ ...this.props.course, namespaces });
  },

  poll() {
    return setInterval(() => {
      if (this.state.updateCount > MAX_UPDATE_COUNT) { return; }
      if (!this.props.editable) {
        this.props.refetchCourse(this.props.course.slug);
        this.setState({
          updateCount: this.state.updateCount + 1
        });
      }
    }, POLL_INTERVAL);
  },

  timeout: null,

  render() {
    const canRename = this.canRename();
    const isClassroomProgramType = this.props.course.type === 'ClassroomProgramCourse';
    const timelineDatesDiffer = this.props.course.start !== this.props.course.timeline_start || this.props.course.end !== this.props.course.timeline_end;
    let campus;
    let staff;
    let school;
    let academic_system;
    if (Features.wikiEd) {
      staff = <WikiEdStaff {...this.props} />;
      campus = <CampusVolunteers {...this.props} />;
    }
    let online;
    if (Features.wikiEd || this.props.course.online_volunteers_enabled) {
      online = <OnlineVolunteers {...this.props} />;
    }

    if (this.props.course.school || canRename) {
      school = (
        <TextInput
          onChange={this.updateSlugPart}
          value={canRename ? this.props.course.school : this.props.course.school.replaceAll('_', ' ')}
          value_key="school"
          validation={CourseUtils.courseSlugRegex()}
          editable={canRename}
          type="text"
          label={CourseUtils.i18n('school', this.props.course.string_prefix)}
          required={true}
        />
      );
    }

    if (canRename && isClassroomProgramType) {
      academic_system = (
        <div className="form-group academic_system">
          <span className="text-input-component__label">
            <strong>
              {I18n.t('courses.school_system')}:
            </strong>
            <AcademicSystem
              value={this.props.course.academic_system}
              updateCourseProps={this.props.updateCourse}
            />
          </span>
        </div>
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
    if (this.props.course.passcode !== '****' || this.props.editable) {
      if (this.props.editable) {
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
      } else {
        const studentLink = this.props.course.enroll_url.substring(0, this.props.course.enroll_url.indexOf('/enroll'));
        const enrollToken = `?enroll=${this.props.course.passcode}`;
        passcode = (
          <TextInput
            onChange={this.updateDetails}
            value={<a href={`${studentLink}${enrollToken}`}>{this.props.course.passcode}</a>}
            value_key="passcode"
            editable={this.props.editable}
            type="text"
            label={I18n.t('courses.passcode')}
            placeholder={I18n.t('courses.passcode_none')}
            required={!!this.props.course.passcode_required}
          />
        );
      }
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
    let courseFormatSelector;
    let timelineToggle;
    let onlineVolunteersToggle;
    let disableStudentEmailsToggle;
    let wikiEditsToggle;
    let editSettingsToggle;
    let withdrawnSelector;
    let stayInSandboxToggle;
    let retainAvailableArticlesToggle;
    let wikiSelector;
    let multiWikiSelector;
    let namespaceSelector;

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
      stayInSandboxToggle = (
        <StayInSandboxToggle
          course={this.props.course}
          editable={this.props.editable}
          updateCourse={this.props.updateCourse}
        />
      );
      retainAvailableArticlesToggle = (
        <RetainAvailableArticlesToggle
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
      courseFormatSelector = (
        <CourseFormatSelector
          format={this.props.course.format}
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

    // Users who can rename a course are also allowed to toggle the student email on/off.
    // But email is only relevant for Wiki Education courses.
    if (canRename && Features.wikiEd) {
      disableStudentEmailsToggle = (
        <DisableStudentEmailsToggle
          course={this.props.course}
          editable={this.props.editable}
          updateCourse={this.props.updateCourse}
        />
      );
    }

    // Users who can rename a course can enable Online Volunteers to join
    if (canRename && !Features.wikiEd) {
      onlineVolunteersToggle = (
        <OnlineVolunteersToggle
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

      if (this.props.course.wiki_edits_enabled) {
        editSettingsToggle = (
          <EditSettingsToggle
            course={this.props.course}
            editable={this.props.editable}
            updateCourse={this.props.updateCourse}
          />
        );
      }
    }
    const home_wiki = { language: this.props.course.home_wiki.language, project: this.props.course.home_wiki.project };

    // It is always visible if you're an admin.
    // It is always visible if it is P&E Dashboard.
    // It is visible if it is Wiki Education and is in Edit Mode
    if (this.props.current_user.admin || !Features.wikiEd || (this.props.editable && Features.wikiEd && !isClassroomProgramType)) {
      wikiSelector = (
        <div className="form-group home-wiki">
          <span className="text-input-component__label">
            <strong>
              {I18n.t('courses.home_wiki')}:&nbsp;
            </strong>
          </span>
          <WikiSelect
            wikis={
              [home_wiki]
            }
            readOnly={!this.props.editable}
            onChange={this.handleWikiChange}
            options={WIKI_OPTIONS}
            multi={false}
            styles={{ ...selectStyles, singleValue: null }}
          />
        </div>
      );
      multiWikiSelector = (
        <div className="form-group multi-wiki">
          <span className="text-input-component__label">
            <strong>
              {I18n.t('courses.multi_wiki')}:&nbsp;
            </strong>
          </span>
          <WikiSelect
            wikis={this.props.course.wikis}
            homeWiki={home_wiki}
            readOnly={!this.props.editable}
            options={WIKI_OPTIONS}
            onChange={this.handleMultiWikiChange}
            multi={true}
            styles={{ ...selectStyles, singleValue: null }}
          />
        </div>
      );

      namespaceSelector = (
        <div className="form-group namespace-select">
          <span className="text-input-component__label">
            <strong>
              {I18n.t('courses.namespaces')}:&nbsp;
            </strong>
          </span>
          <div className="tooltip-trigger">
            <img src ="/assets/images/info.svg" alt = "tooltip default logo" />
            <div className="tooltip large dark">
              <p>
                {I18n.t('namespace.tracked_namespaces_info')}
              </p>
            </div>
          </div>
          <NamespaceSelect
            wikis={this.props.course.wikis}
            namespaces={this.props.course.namespaces}
            onChange={this.handleNamespaceChange}
            readOnly={!this.props.editable}
            styles={{ ...selectStyles, singleValue: null }}
          />
        </div>
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
              {academic_system}
              {wikiSelector}
              {multiWikiSelector}
              {namespaceSelector}
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
              {courseFormatSelector}
              {tags}
              {courseTypeSelector}
              {submittedSelector}
              {stayInSandboxToggle}
              {retainAvailableArticlesToggle}
              {privacySelector}
              {timelineToggle}
              {onlineVolunteersToggle}
              {disableStudentEmailsToggle}
              {wikiEditsToggle}
              {editSettingsToggle}
              {withdrawnSelector}
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

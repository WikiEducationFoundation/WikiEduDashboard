import React, { useState, useEffect, useCallback } from 'react';
import PropTypes from 'prop-types';

import Instructors from './instructors';
import OnlineVolunteers from './online_volunteers';
import CampusVolunteers from './campus_volunteers';
import WikiEdStaff from './wiki_ed_staff';

import CampaignEditable from './campaign_editable.jsx';
import CampaignList from './campaign_list.jsx';
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

import TextInput from '../common/text_input.jsx';
import Notifications from '../common/notifications.jsx';

import DatePicker from '../common/date_picker.jsx';

import CourseUtils from '../../utils/course_utils.js';
import CourseDateUtils from '../../utils/course_date_utils.js';
import AcademicSystem from '../common/academic_system.jsx';

const POLL_INTERVAL = 60000; // 1 minute
const MAX_UPDATE_COUNT = 60 * 12; // 12 hours of updates

const Details = (props) => {
  const [updateCount, setUpdateCount] = useState(0);
  const [timeoutId, setTimeoutId] = useState(null);

  const { course, current_user, campaigns, editable, updateCourse, refetchCourse } = props;

  useEffect(() => {
    const poll = () => setInterval(() => {
      if (updateCount > MAX_UPDATE_COUNT) return;
      if (!editable) {
        refetchCourse(course.slug);
        setUpdateCount(updateCount + 1);
      }
    }, POLL_INTERVAL);

    setTimeoutId(poll());

    return () => clearInterval(timeoutId);
  }, [updateCount, editable, refetchCourse, course.slug, timeoutId]);

  const updateDetails = useCallback((valueKey, value) => {
    const updatedCourse = { ...course, [valueKey]: value };
    updateCourse(updatedCourse);
  }, [course, updateCourse]);

  const updateSlugPart = useCallback((valueKey, value) => {
    const updatedCourse = { ...course, [valueKey]: value, slug: CourseUtils.generateTempId(course) };
    updateCourse(updatedCourse);
  }, [course, updateCourse]);

  const updateCourseDates = useCallback((valueKey, value) => {
    const updatedCourse = CourseDateUtils.updateCourseDates(course, valueKey, value);
    updateCourse(updatedCourse);
  }, [course, updateCourse]);

  const canRename = useCallback(() => {
    if (!editable) return false;
    if (current_user.admin) return true;
    if (Features.wikiEd) return false;
    return true;
  }, [editable, current_user]);

  const canRenameValue = canRename();
  const isClassroomProgramType = course.type === 'ClassroomProgramCourse';
  const timelineDatesDiffer = course.start !== course.timeline_start || course.end !== course.timeline_end;

  let campus;
  let staff;
  let school;
  let academic_system;

  if (Features.wikiEd) {
    staff = <WikiEdStaff {...props} />;
    campus = <CampusVolunteers {...props} />;
  }

  let online;
  if (Features.wikiEd || course.online_volunteers_enabled) {
    online = <OnlineVolunteers {...props} />;
  }

  if (course.school || canRenameValue) {
    school = (
      <TextInput
        id="school-input"
        onChange={updateSlugPart}
        value={course.school}
        value_key="school"
        validation={CourseUtils.courseSlugRegex()}
        editable={canRenameValue}
        type="text"
        label={CourseUtils.i18n('school', course.string_prefix)}
        required={true}
      />
    );
  }

  if (canRenameValue && isClassroomProgramType) {
    academic_system = (
      <div className="form-group academic_system">
        <span className="text-input-component__label">
          <strong>
            {I18n.t('courses.school_system')}:
          </strong>
          <AcademicSystem
            value={course.academic_system}
            updateCourseProps={updateCourse}
          />
        </span>
      </div>
    );
  }

  let title;
  if (canRenameValue) {
    title = (
      <TextInput
        id="title-input"
        onChange={updateSlugPart}
        value={course.title}
        value_key="title"
        validation={CourseUtils.courseSlugRegex()}
        editable={canRenameValue}
        type="text"
        label={CourseUtils.i18n('title', course.string_prefix)}
        required={true}
      />
    );
  }

  let term;
  if (course.term || canRenameValue) {
    term = (
      <TextInput
        id="term-input"
        onChange={updateSlugPart}
        value={course.term}
        value_key="term"
        validation={CourseUtils.courseSlugRegex()}
        editable={canRenameValue}
        type="text"
        label={CourseUtils.i18n('term', course.string_prefix)}
        required={false}
      />
    );
  }

  let passcode;
  if (course.passcode !== '****' || editable) {
    if (editable) {
      passcode = (
        <TextInput
          id="passcode-input-editable"
          onChange={updateDetails}
          value={course.passcode}
          value_key="passcode"
          editable={editable}
          type="text"
          label={I18n.t('courses.passcode')}
          placeholder={I18n.t('courses.passcode_none')}
          required={!!course.passcode_required}
        />
      );
    } else {
      const studentLink = course.enroll_url.substring(0, course.enroll_url.indexOf('/enroll'));
      const enrollToken = `?enroll=${course.passcode}`;
      passcode = (
        <TextInput
          id="passcode-input"
          onChange={updateDetails}
          value={<a href={`${studentLink}${enrollToken}`}>{course.passcode}</a>}
          value_key="passcode"
          editable={editable}
          type="text"
          label={I18n.t('courses.passcode')}
          placeholder={I18n.t('courses.passcode_none')}
          required={!!course.passcode_required}
        />
      );
    }
  }

  let expectedStudents;
  if ((course.expectedStudents || course.expectedStudents === 0 || editable) && isClassroomProgramType) {
    expectedStudents = (
      <TextInput
        id="expected-students"
        onChange={updateDetails}
        value={String(course.expectedStudents)}
        value_key="expectedStudents"
        editable={editable}
        type="number"
        label={CourseUtils.i18n('expectedStudents', course.string_prefix)}
      />
    );
  }

  const dateProps = CourseDateUtils.dateProps(course);
  let timelineStart;
  let timelineEnd;
  if (timelineDatesDiffer || editable) {
    timelineStart = (
      <DatePicker
        onChange={updateCourseDates}
        value={course.timeline_start}
        value_key="timeline_start"
        editable={editable}
        validation={CourseDateUtils.isDateValid}
        label={CourseUtils.i18n('assignment_start', course.string_prefix)}
        date_props={dateProps.timeline_start}
        showTime={course.use_start_and_end_times}
        required={true}
      />
    );

    timelineEnd = (
      <DatePicker
        onChange={updateCourseDates}
        value={course.timeline_end}
        value_key="timeline_end"
        editable={editable}
        validation={CourseDateUtils.isDateValid}
        label={CourseUtils.i18n('assignment_end', course.string_prefix)}
        date_props={dateProps.timeline_end}
        showTime={course.use_start_and_end_times}
        required={true}
      />
    );
  }

  let project;
  if (course.project || canRenameValue) {
    project = (
      <TextInput
        id="project-input"
        onChange={updateSlugPart}
        value={course.project}
        value_key="project"
        validation={CourseUtils.courseSlugRegex()}
        editable={canRenameValue}
        type="text"
        label={CourseUtils.i18n('course_title', course.string_prefix)}
        required={false}
      />
    );
  }

  let subject;
  if (course.subject || canRenameValue) {
    subject = (
      <TextInput
        id="subject-input"
        onChange={updateSlugPart}
        value={course.subject}
        value_key="subject"
        validation={CourseUtils.courseSlugRegex()}
        editable={canRenameValue}
        type="text"
        label={CourseUtils.i18n('subject', course.string_prefix)}
        required={false}
      />
    );
  }

  let expectedStudentsField;
  if (editable && isClassroomProgramType) {
    expectedStudentsField = (
      <TextInput
        id="expected-students"
        onChange={updateDetails}
        value={course.expectedStudents}
        value_key="expected_students"
        editable={editable}
        type="number"
        label={CourseUtils.i18n('expected_students', course.string_prefix)}
      />
    );
  }

  let instructors;
  if (Features.wikiEd) {
    instructors = (
      <Instructors {...props} />
    );
  }

  const removeCampaigns = campaigns.map(campaign => campaign.slug);

  return (
    <div className="module course-details">
      <Notifications {...props} />

      <h3 className="course-details__header">{CourseUtils.i18n('details', course.string_prefix)}</h3>
      <div className="form-group">
        {title}
        {term}
      </div>
      <div className="form-group">
        {school}
        {project}
      </div>
      <div className="form-group">
        {academic_system}
        {subject}
      </div>
      <div className="form-group">
        <CourseTypeSelector
          course={course}
          editable={editable}
          updateCourse={updateCourse}
          string_prefix={course.string_prefix}
        />
      </div>
      <div className="form-group">
        {expectedStudentsField}
      </div>
      <div className="form-group">
        <CourseLevelSelector
          level={course.level}
          editable={editable}
          updateCourse={updateCourse}
          string_prefix={course.string_prefix}
        />
        <CourseFormatSelector
          format={course.format}
          editable={editable}
          updateCourse={updateCourse}
          string_prefix={course.string_prefix}
        />
      </div>
      <div className="form-group">
        {timelineStart}
        {timelineEnd}
      </div>
      <div className="form-group">
        <WikiSelect
          home_wiki={course.home_wiki}
          updateCourse={updateCourse}
          selectedWikis={course.wikis}
          multiSelect={false}
          styles={selectStyles}
        />
        <NamespaceSelect
          wikis={course.wikis}
          updateCourse={updateCourse}
          selectedNamespaces={course.namespaces}
        />
        {Features.multiCourseWiki && <WikiSelect
          home_wiki={course.home_wiki}
          updateCourse={updateCourse}
          selectedWikis={course.wikis}
          multiSelect
          styles={selectStyles}
        />}
      </div>
      <div className="form-group">
        {passcode}
      </div>
      <div className="form-group">
        <TagEditable {...props} />
      </div>
      <div className="form-group">
        <CampaignEditable
          campaigns={removeCampaigns}
          {...props}
        />
        <CampaignList {...props} />
      </div>
      <div className="form-group">
        <SubmittedSelector
          editable={editable}
          submitted={course.submitted}
          updateCourse={updateCourse}
        />
        <WithdrawnSelector
          editable={editable}
          withdrawn={course.withdrawn}
          updateCourse={updateCourse}
        />
        <PrivacySelector
          editable={editable}
          course={course}
          updateCourse={updateCourse}
        />
        <TimelineToggle
          editable={editable}
          timeline_enabled={course.timeline_enabled}
          updateCourse={updateCourse}
        />
        <OnlineVolunteersToggle
          editable={editable}
          online_volunteers_enabled={course.online_volunteers_enabled}
          updateCourse={updateCourse}
        />
        <DisableStudentEmailsToggle
          editable={editable}
          disable_student_emails={course.disable_student_emails}
          updateCourse={updateCourse}
        />
        <StayInSandboxToggle
          editable={editable}
          stay_in_sandbox={course.stay_in_sandbox}
          updateCourse={updateCourse}
        />
        <RetainAvailableArticlesToggle
          editable={editable}
          retain_available_articles={course.retain_available_articles}
          updateCourse={updateCourse}
        />
        <WikiEditsToggle
          editable={editable}
          wiki_edits_enabled={course.wiki_edits_enabled}
          updateCourse={updateCourse}
        />
        <EditSettingsToggle
          editable={editable}
          edit_settings={course.edit_settings}
          updateCourse={updateCourse}
        />
      </div>
      {staff}
      {campus}
      {online}
      {instructors}
      <Modal />
    </div>
  );
};

Details.propTypes = {
  course: PropTypes.object.isRequired,
  current_user: PropTypes.object.isRequired,
  campaigns: PropTypes.array.isRequired,
  editable: PropTypes.bool.isRequired,
  updateCourse: PropTypes.func.isRequired,
  refetchCourse: PropTypes.func.isRequired,
};

export default Details;

import React, { useState, useEffect } from 'react';
import PropTypes from 'prop-types';

import Instructors from './instructors';
import OnlineVolunteers from './online_volunteers';
import CampusVolunteers from './campus_volunteers';
import WikiEdStaff from './wiki_ed_staff';

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

const Details = ({
  course,
  current_user,
  campaigns,
  controls,
  editable,
  updateCourse,
  refetchCourse,
  firstErrorMessage
}) => {
  const [updateCount, setUpdateCount] = useState(0);

  useEffect(() => {
    const timeout = poll();

    return () => {
      clearInterval(timeout); // Cleanup on unmount
    };
  }, [updateCount]);

  const updateDetails = (valueKey, value) => {
    const updatedCourse = { ...course, [valueKey]: value };
    updateCourse(updatedCourse);
  };

  const updateSlugPart = (valueKey, value) => {
    const updatedCourse = { ...course, [valueKey]: value };
    updatedCourse.slug = CourseUtils.generateTempId(updatedCourse);
    updateCourse(updatedCourse);
  };

  const updateCourseDates = (valueKey, value) => {
    const updatedCourse = CourseDateUtils.updateCourseDates(course, valueKey, value);
    updateCourse(updatedCourse);
  };

  const canRename = () => {
    if (!editable) return false;
    if (current_user.admin) return true;
    if (Features.wikiEd) return false;
    return true;
  };

  const handleWikiChange = (wiki) => {
    const home_wiki = wiki.value;
    const { id, ...prev_wiki } = course.home_wiki;
    const wikis = CourseUtils.normalizeWikis([...course.wikis], home_wiki, prev_wiki);
    updateCourse({ ...course, wikis, home_wiki });
  };

  const handleMultiWikiChange = (wikis) => {
    wikis = wikis.map(wiki => wiki.value);
    const home_wiki = {
      language: course.home_wiki.language || 'www',
      project: course.home_wiki.project
    };
    wikis = CourseUtils.normalizeWikis(wikis, home_wiki);
    updateCourse({ ...course, wikis });
  };

  const handleNamespaceChange = (namespaces) => {
    updateCourse({ ...course, namespaces });
  };

  const poll = () => {
    return setInterval(() => {
      if (updateCount > MAX_UPDATE_COUNT) return;
      if (!editable) {
        refetchCourse(course.slug);
        setUpdateCount(prevCount => prevCount + 1);
      }
    }, POLL_INTERVAL);
  };

  const isClassroomProgramType = course.type === 'ClassroomProgramCourse';
  const timelineDatesDiffer = course.start !== course.timeline_start || course.end !== course.timeline_end;

  let campus;
  let staff;
  let school;
  let academic_system;

  if (Features.wikiEd) {
    staff = <WikiEdStaff {...{ course, current_user, campaigns, controls, editable, updateCourse, refetchCourse, firstErrorMessage }} />;
    campus = <CampusVolunteers {...{ course, current_user, campaigns, controls, editable, updateCourse, refetchCourse, firstErrorMessage }} />;
  }

  let online;
  if (Features.wikiEd || course.online_volunteers_enabled) {
    online = <OnlineVolunteers {...{ course, current_user, campaigns, controls, editable, updateCourse, refetchCourse, firstErrorMessage }} />;
  }

  if (course.school || canRename()) {
    school = (
      <TextInput
        id="school-input"
        onChange={updateSlugPart}
        value={course.school}
        value_key="school"
        validation={CourseUtils.courseSlugRegex()}
        editable={canRename()}
        type="text"
        label={CourseUtils.i18n('school', course.string_prefix)}
        required={true}
      />
    );
  }

  if (canRename() && isClassroomProgramType) {
    academic_system = (
      <div className="form-group academic_system">
        <span className="text-input-component__label">
          <strong>{I18n.t('courses.school_system')}:</strong>
          <AcademicSystem
            value={course.academic_system}
            updateCourseProps={updateCourse}
          />
        </span>
      </div>
    );
  }

  let title;
  if (canRename()) {
    title = (
      <TextInput
        id="title-input"
        onChange={updateSlugPart}
        value={course.title}
        value_key="title"
        validation={CourseUtils.courseSlugRegex()}
        editable={canRename()}
        type="text"
        label={CourseUtils.i18n('title', course.string_prefix)}
        required={true}
      />
    );
  }

  let term;
  if (course.term || canRename()) {
    term = (
      <TextInput
        id="term-input"
        onChange={updateSlugPart}
        value={course.term}
        value_key="term"
        validation={CourseUtils.courseSlugRegex()}
        editable={canRename()}
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
  if ((course.expected_students || course.expected_students === 0 || editable) && isClassroomProgramType) {
    expectedStudents = (
      <TextInput
        id="expected-students"
        onChange={updateDetails}
        value={String(course.expected_students)}
        value_key="expected_students"
        editable={editable}
        type="number"
        label={CourseUtils.i18n('expected_students', course.string_prefix)}
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

  if (current_user.admin) {
    subject = (
      <TextInput
        id="course-subject-selector"
        onChange={updateDetails}
        value={course.subject}
        value_key="subject"
        editable={editable}
        type="text"
        label={I18n.t('courses.subject')}
      />
    );
    tags = (
      <div className="tags">
        <TagList course={course} />
        <TagEditable {...props} show={editable} />
      </div>
    );
    submittedSelector = (
      <SubmittedSelector
        course={course}
        editable={editable}
        updateCourse={updateCourse}
      />
    );
    withdrawnSelector = (
      <WithdrawnSelector
        course={course}
        editable={editable}
        updateCourse={updateCourse}
      />
    );
    stayInSandboxToggle = (
      <StayInSandboxToggle
        course={course}
        editable={editable}
        updateCourse={updateCourse}
      />
    );
    retainAvailableArticlesToggle = (
      <RetainAvailableArticlesToggle
        course={course}
        editable={editable}
        updateCourse={updateCourse}
      />
    );
  }

  if (canRename) {
    courseTypeSelector = (
      <CourseTypeSelector
        course={course}
        editable={editable}
        updateCourse={updateCourse}
      />
    );
    privacySelector = (
      <PrivacySelector
        course={course}
        editable={editable}
        updateCourse={updateCourse}
      />
    );
  }

  if (editable && isClassroomProgramType) {
    courseLevelSelector = (
      <CourseLevelSelector
        level={course.level}
        updateCourse={updateDetails}
      />
    );
    courseFormatSelector = (
      <CourseFormatSelector
        format={course.format}
        updateCourse={updateDetails}
      />
    );
  }

  if (canRename && !isClassroomProgramType) {
    timelineToggle = (
      <TimelineToggle
        course={course}
        editable={editable}
        updateCourse={updateCourse}
      />
    );
  }

  if (canRename && Features.wikiEd) {
    disableStudentEmailsToggle = (
      <DisableStudentEmailsToggle
        course={course}
        editable={editable}
        updateCourse={updateCourse}
      />
    );
  }

  if (canRename && !Features.wikiEd) {
    onlineVolunteersToggle = (
      <OnlineVolunteersToggle
        course={course}
        editable={editable}
        updateCourse={updateCourse}
      />
    );
  }

  if (canRename && !isClassroomProgramType && course.home_wiki_edits_enabled) {
    wikiEditsToggle = (
      <WikiEditsToggle
        course={course}
        editable={editable}
        updateCourse={updateCourse}
      />
    );

    if (course.wiki_edits_enabled) {
      editSettingsToggle = (
        <EditSettingsToggle
          course={course}
          editable={editable}
          updateCourse={updateCourse}
        />
      );
    }
  }

  const home_wiki = { language: course.home_wiki.language, project: course.home_wiki.project };

  if (current_user.admin || !Features.wikiEd || (editable && Features.wikiEd && !isClassroomProgramType)) {
    wikiSelector = (
      <div className="form-group home-wiki">
        <WikiSelect
          id="home_wiki"
          label={I18n.t('courses.home_wiki')}
          wikis={[home_wiki]}
          readOnly={!editable}
          onChange={handleWikiChange}
          options={WIKI_OPTIONS}
          multi={false}
          styles={{ ...selectStyles, singleValue: null }}
        />
      </div>
    );
    multiWikiSelector = (
      <div className="form-group multi-wiki">
        <WikiSelect
          id="multi_wiki"
          label={I18n.t('courses.multi_wiki')}
          wikis={course.wikis}
          homeWiki={home_wiki}
          readOnly={!editable}
          options={WIKI_OPTIONS}
          onChange={handleMultiWikiChange}
          multi={true}
          styles={{ ...selectStyles, singleValue: null }}
        />
      </div>
    );

    namespaceSelector = (
      <div className="form-group namespace-select">
        <NamespaceSelect
          wikis={course.wikis}
          namespaces={course.namespaces}
          onChange={handleNamespaceChange}
          readOnly={!editable}
          styles={{ ...selectStyles, singleValue: null }}
        />
      </div>
    );
  }

  const shared = (
    <div className="module course-details">
      <div className="section-header">
        <h3>{I18n.t('application.details')}</h3>
        {controls()}
      </div>
      <div className="module__data extra-line-height">
        <Instructors {...props} />
        <div className="details-form">
          <div className="group-left">
            {online}
            {campus}
            {staff}
            <div><p className="red">{firstErrorMessage}</p></div>
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
                onChange={updateCourseDates}
                value={course.start}
                value_key="start"
                validation={CourseDateUtils.isDateValid}
                editable={editable}
                label={CourseUtils.i18n('start', course.string_prefix)}
                showTime={course.use_start_and_end_times}
                required={true}
              />
              <DatePicker
                onChange={updateCourseDates}
                value={course.end}
                value_key="end"
                editable={editable}
                validation={CourseDateUtils.isDateValid}
                label={CourseUtils.i18n('end', course.string_prefix)}
                date_props={dateProps.end}
                enabled={Boolean(course.start)}
                showTime={course.use_start_and_end_times}
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

  if (!editable) {
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
};

Details.propTypes = {
  course: PropTypes.object.isRequired,
  current_user: PropTypes.object.isRequired,
  campaigns: PropTypes.array.isRequired,
  controls: PropTypes.func.isRequired,
  editable: PropTypes.bool.isRequired,
  updateCourse: PropTypes.func.isRequired,
  refetchCourse: PropTypes.func.isRequired,
  firstErrorMessage: PropTypes.string
};

export default EditableRedux(Details, I18n.t('editable.edit_details'));
import React from 'react';
import TextAreaInput from '../common/text_area_input.jsx';
import CreatableInput from '../common/creatable_input.jsx';
import TextInput from '../common/text_input.jsx';
import CourseLevelSelector from './course_level_selector.jsx';
import CourseUtils from '../../utils/course_utils.js';
import selectStyles from '../../styles/select';
import WikiSelect from '../common/wiki_select.jsx';

const CourseForm = (props) => {
  const updateCoursePrivacy = (e) => {
    const isPrivate = e.target.checked;
    props.updateCourseProps({ private: isPrivate });
    props.updateCourseAction('private', isPrivate);
  };

  const handleWikiChange = (wiki) => {
    wiki = wiki.value;
    props.updateCourseProps({ ...wiki });
  };

  const handleMultiWikiChange = (wikis) => {
    wikis = wikis.map(wiki => wiki.value);
    props.updateCourseProps({ wikis });
  };

  const backClass = `dark button ${props.backCondition ? 'hidden' : ''}`;
  let term;
  let subject;
  let expectedStudents;
  let courseLevel;
  let roleDescription;

  let descriptionRequired = false;
  if (props.defaultCourse === 'ClassroomProgramCourse') {
    descriptionRequired = true;
    term = (
      <TextInput
        id="course_term"
        onChange={props.updateCourseAction}
        value={props.course.term}
        value_key="term"
        required
        validation={CourseUtils.courseSlugRegex()}
        editable
        label={CourseUtils.i18n('creator.course_term', props.stringPrefix)}
        placeholder={CourseUtils.i18n('creator.course_term_placeholder', props.stringPrefix)}
      />
    );
    subject = (
      <TextInput
        id="course_subject"
        onChange={props.updateCourseAction}
        value={props.course.subject}
        value_key="subject"
        editable
        label={CourseUtils.i18n('creator.course_subject', props.stringPrefix)}
        placeholder={I18n.t('courses.creator.subject')}
      />
    );
    courseLevel = (
      <CourseLevelSelector
        level={props.course.level}
        updateCourse={props.updateCourseAction}
      />
    );
    expectedStudents = (
      <TextInput
        id="course_expected_students"
        onChange={props.updateCourseAction}
        value={String(props.course.expected_students)}
        value_key="expected_students"
        editable
        required
        type="number"
        max="999"
        label={CourseUtils.i18n('creator.expected_number', props.stringPrefix)}
        placeholder={CourseUtils.i18n('creator.expected_number', props.stringPrefix)}
      />
    );
    const options = I18n.t('courses.creator.role_description_options').map((value) => {
      return { label: value, value };
    });

    roleDescription = (
      <CreatableInput
        id="role_description"
        onChange={({ value }) => props.updateCourseAction('role_description', value)}
        label={I18n.t('courses.creator.role_description')}
        placeholder={I18n.t('courses.creator.role_description_placeholder')}
        options={options}
      />
    );
  }

  let privacyCheckbox;
  let campaign;
  let backButton;
  let home_wiki;
  let multi_wiki;

  if (props.defaultCourse !== 'ClassroomProgramCourse') {
    home_wiki = (
      <div className="form-group">
        <span className="text-input-component__label">
          <strong>
            {I18n.t('courses.home_wiki')}:
          </strong>
        </span>
        <WikiSelect
          wikis={[{ language: 'en', project: 'wikipedia' }]}
          onChange={handleWikiChange}
          multi={false}
          styles={{ ...selectStyles, singleValue: null }}
        />
      </div>
    );
    multi_wiki = (
      <div className="form-group">
        <span className="text-input-component__label">
          <strong>
            {I18n.t('courses.multi_wiki')}:
          </strong>
        </span>
        <WikiSelect
          wikis={props.course.wikis}
          onChange={handleMultiWikiChange}
          multi={true}
          styles={{ ...selectStyles, singleValue: null }}
        />
      </div>
    );
    privacyCheckbox = (
      <div className="form-group">
        <label htmlFor="course_private">{I18n.t('courses.creator.course_private')}:</label>
        <input
          id="course_private"
          type="checkbox"
          value={true}
          onChange={updateCoursePrivacy}
          checked={!!props.course.private}
        />
      </div>
    );
    backButton = (
      <button onClick={props.previous} className={backClass}>Back</button>
    );
  }
  if (props.course.initial_campaign_title) {
    campaign = (
      <TextInput
        value={props.course.initial_campaign_title}
        label={I18n.t('campaign.campaign')}
      />
    );
  }
  return (
    <div className={props.courseFormClass}>
      <div className="column">

        {campaign}
        <TextInput
          id="course_title"
          onChange={props.updateCourseAction}
          value={props.course.title}
          value_key="title"
          required
          validation={CourseUtils.courseSlugRegex()}
          editable
          label={CourseUtils.i18n('creator.course_title', props.stringPrefix)}
          placeholder={CourseUtils.i18n('creator.course_title', props.stringPrefix)}
        />
        <TextInput
          id="course_school"
          onChange={props.updateCourseAction}
          value={props.course.school}
          value_key="school"
          required
          validation={CourseUtils.courseSlugRegex()}
          editable
          label={CourseUtils.i18n('creator.course_school', props.stringPrefix)}
          placeholder={CourseUtils.i18n('creator.course_school', props.stringPrefix)}
        />
        {term}
        {subject}
        {expectedStudents}
        {home_wiki}
        {multi_wiki}
        {backButton}
        <p className="tempCourseIdText">{props.tempCourseId}</p>
      </div>
      <div className="column">
        {courseLevel}
        <span className="text-input-component__label"><strong>{CourseUtils.i18n('creator.course_description', props.stringPrefix)}:</strong></span>
        <TextAreaInput
          id="course_description"
          onChange={props.updateCourseAction}
          value={props.course.description}
          value_key="description"
          required={descriptionRequired}
          editable
          placeholder={CourseUtils.i18n('creator.course_description_placeholder', props.stringPrefix)}
        />
        {roleDescription}
        {privacyCheckbox}
        <button onClick={props.next} id="next" className="dark button button__submit next">Next</button>
      </div>
    </div>
  );
};

export default CourseForm;

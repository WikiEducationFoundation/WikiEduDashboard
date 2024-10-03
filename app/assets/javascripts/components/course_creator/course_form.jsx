import React from 'react';
import TextAreaInput from '../common/text_area_input.jsx';
import CreatableInput from '../common/creatable_input.jsx';
import TextInput from '../common/text_input.jsx';
import CourseLevelSelector from './course_level_selector.jsx';
import CourseFormatSelector from './course_format_selector.jsx';
import CourseSubjectSelector from './course_subject_selector.jsx';
import CourseCheckbox from '../common/course_checkbox.jsx';
import CourseUtils from '../../utils/course_utils.js';
import selectStyles from '../../styles/select';
import WikiSelect from '../common/wiki_select.jsx';
import AcademicSystem from '../common/academic_system.jsx';
import WIKI_OPTIONS from '../../utils/wiki_options';

const CourseForm = (props) => {
  const handleWikiChange = (wiki) => {
    const home_wiki = wiki.value;
    const prev_wiki = { ...props.course.home_wiki };
    const wikis = CourseUtils.normalizeWikis(
      [...props.course.wikis],
      home_wiki,
      prev_wiki
    );
    props.updateCourseProps({ home_wiki, wikis });
  };
  const handleMultiWikiChange = (wikis) => {
    wikis = wikis.map(wiki => wiki.value);
    const home_wiki = { ...props.course.home_wiki };
    wikis = CourseUtils.normalizeWikis(wikis, home_wiki);
    props.updateCourseProps({ wikis });
  };

  let term;
  let courseSubject;
  let expectedStudents;
  let courseLevel;
  let courseFormat;
  let roleDescription;
  let academic_system;
  let taSupportCheckbox;

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
        placeholder={CourseUtils.i18n(
          'creator.course_term_placeholder',
          props.stringPrefix
        )}
      />
    );
    courseSubject = (
      <CourseSubjectSelector
        updateCourse={props.updateCourseAction}
      />
    );
    courseLevel = (
      <CourseLevelSelector
        level={props.course.level}
        updateCourse={props.updateCourseAction}
      />
    );
    courseFormat = (
      <CourseFormatSelector
        format={props.course.format}
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
        placeholder={CourseUtils.i18n(
          'creator.expected_number',
          props.stringPrefix
        )}
      />
    );
    const options = I18n.t('courses.creator.role_description_options').map(
      (value) => {
        return { label: value, value };
      }
    );
    academic_system = (
      <div className="form-group academic_system">
        <span className="text-input-component__label">
          <strong>{I18n.t('courses.school_system')}:</strong>
          <AcademicSystem
            value={props.course.academic_system}
            updateCourseProps={props.updateCourseProps}
          />
        </span>
      </div>
    );
    taSupportCheckbox = (
      <CourseCheckbox
        checkboxFor="ta_support"
        value={true}
        updateCourseProps={props.updateCourseProps}
        checked={!!props.course.ta_support}
        text={I18n.t('courses.creator.course_ta_support')}
      />
    );
    roleDescription = (
      <div className="form-group">
        <CreatableInput
          id="role_description"
          onChange={({ value }) =>
            props.updateCourseAction('role_description', value)
      }
          label={I18n.t('courses.creator.role_description')}
          placeholder={I18n.t('courses.creator.role_description_placeholder')}
          options={options}
        />
      </div>
    );
  }


  let privacyCheckbox;
  let campaign;
  let home_wiki;
  let multi_wiki;

  if (props.course.wikis && !props.course.wikis.length) {
    props.course.wikis.push({ language: 'en', project: 'wikipedia' });
  }

  if (props.defaultCourse !== 'ClassroomProgramCourse') {
    home_wiki = (
      <div className="form-group home-wiki">
        <WikiSelect
          id="home-wiki-select"
          label={I18n.t('courses.home_wiki')}
          wikis={[{ ...props.course.home_wiki }]}
          onChange={handleWikiChange}
          options={WIKI_OPTIONS}
          multi={false}
          styles={{ ...selectStyles, singleValue: null }}
        />
      </div>
    );
    multi_wiki = (
      <div className="form-group multi-wiki">
        <WikiSelect
          id="tracked-wikis-select"
          label={I18n.t('courses.multi_wiki')}
          wikis={props.course.wikis}
          onChange={handleMultiWikiChange}
          multi={true}
          homeWiki={{ ...props.course.home_wiki }}
          styles={{ ...selectStyles, singleValue: null }}
        />
      </div>
    );
    privacyCheckbox = (
      <CourseCheckbox
        checkboxFor="private"
        value={true}
        updateCourseProps={props.updateCourseProps}
        checked={!!props.course.private}
        text={I18n.t('courses.creator.course_private')}
      />
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
  let backCondition;
  if (Features.wikiEd) {
    backCondition = props.previousWikiEd;
  } else {
    backCondition = props.previous;
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
          placeholder={CourseUtils.i18n(
            'creator.course_title',
            props.stringPrefix
          )}
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
          placeholder={CourseUtils.i18n(
            'creator.course_school',
            props.stringPrefix
          )}
        />
        {academic_system}
        {term}
        {courseSubject}
        {expectedStudents}
        {home_wiki}
        {multi_wiki}
        <div className="backButtonContainer">
          <button onClick={backCondition} className="button dark">{I18n.t('application.back')}</button>
          <p className="tempEduCourseIdText">
            {props.tempCourseId || '\xa0'}
          &nbsp;
            <span className="red">{props.firstErrorMessage || '\xa0'}</span>
          </p>
        </div>

      </div>
      <div className="column">
        {courseLevel}
        {courseFormat}
        <span className="text-input-component__label">
          <strong>
            {CourseUtils.i18n('creator.course_description', props.stringPrefix)}
            :
          </strong>
        </span>
        <TextAreaInput
          id="course_description"
          onChange={props.updateCourseAction}
          value={props.course.description}
          value_key="description"
          required={descriptionRequired}
          editable
          placeholder={CourseUtils.i18n(
            'creator.course_description_placeholder',
            props.stringPrefix
          )}
        />
        {roleDescription}
        {taSupportCheckbox}
        {privacyCheckbox}
        <button
          onClick={props.next}
          id="next"
          className="dark button button__submit next"
        >
          Next
        </button>
      </div>
    </div>
  );
};

export default CourseForm;

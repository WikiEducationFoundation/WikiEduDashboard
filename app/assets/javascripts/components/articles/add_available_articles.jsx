import React, { useState } from 'react';
import PropTypes from 'prop-types';
import TextAreaInput from '../common/text_area_input';
import CourseUtils from '../../utils/course_utils.js';
import ArticleUtils from '../../utils/article_utils';

const AddAvailableArticles = ({
  course_id,
  role,
  project,
  language,
  addAssignment,
  open,
}) => {
  const [state, setState] = useState({ assignments: '' });

  const updateInput = (_key, value) => {
    setState({ assignments: value });
  };

  const resetInput = () => {
    setState({ assignments: '' });
    open();
  };

  const chainSubmissions = (assignments, promise) => {
    const assignment = assignments.shift();
    if (assignment === undefined) return promise;

    let extendedPromise;
    if (promise) {
      extendedPromise = promise.then(() => addAssignment(assignment));
    } else {
      extendedPromise = addAssignment(assignment);
    }
    return chainSubmissions(assignments, extendedPromise);
  };

  const submit = () => {
    const inputLines = state.assignments.match(/[^\r\n]+/g);
    const assignmentsArray = inputLines.map((assignmentString) => {
      const assignment = CourseUtils.articleFromTitleInput(assignmentString);
      const lang = assignment.language ? assignment.language : language;
      const proj = assignment.project ? assignment.project : project;
      return {
        title: assignment.title,
        project: proj,
        language: lang,
        course_slug: course_id,
        role: role,
      };
    });

    return chainSubmissions(assignmentsArray).then(() => resetInput());
  };

  const isWikidata = project === 'wikidata';
  const inputId = isWikidata ? 'add_available_items' : 'add_available_articles';
  const inputPlaceholder = isWikidata
    ? I18n.t('assignments.add_available_placeholder_wikidata')
    : I18n.t('assignments.add_available_placeholder');

  return (
    <div className="pop__padded-content">
      <TextAreaInput
        id={inputId}
        onChange={updateInput}
        value={state.assignments}
        value_key="assignments"
        editable
        placeholder={inputPlaceholder}
      />
      <button className="button border pull-right" onClick={submit}>
        {I18n.t(`assignments.${ArticleUtils.projectSuffix(project, 'add_available_submit')}`)}
      </button>
    </div>
  );
};

AddAvailableArticles.propTypes = {
  course_id: PropTypes.string,
  course: PropTypes.object,
  role: PropTypes.number.isRequired,
  current_user: PropTypes.object,
  assignments: PropTypes.array,
  project: PropTypes.string,
  language: PropTypes.string,
  addAssignment: PropTypes.func,
  open: PropTypes.func,
};

export default AddAvailableArticles;

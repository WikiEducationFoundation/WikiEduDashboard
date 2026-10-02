import React, { useEffect, useState } from 'react';
import PropTypes from 'prop-types';
import { useDispatch, useSelector } from 'react-redux';
import Select from 'react-select';

import Modal from '../common/modal.jsx';
import selectStyles from '../../styles/single_select.js';
import API from '../../utils/api.js';
import { fetchCoursesForUser } from '../../actions/user_courses_actions';
import { copyAvailableArticles } from '../../actions/assignment_actions';

const PREVIEW_DEBOUNCE_MS = 400;

// The backend reports why a source can't be used (unknown, private, or this
// same course) in the JSON `message`; fall back to the generic error text.
const errorMessageFrom = (error) => {
  try {
    return JSON.parse(error.responseText).message;
  } catch (e) {
    return error.message;
  }
};

// Button plus dialog for copying another course's Available Articles into this
// course. The source is either one of the user's own courses (dropdown) or any
// course URL/slug (text field). The preview shows how many articles would be
// added, net of ones already present here; it comes from the server and
// deliberately bypasses redux, because fetching the source's assignments
// through the store would replace this course's list.
const CopyAvailableArticles = ({ course, course_id, current_user }) => {
  const dispatch = useDispatch();
  const userCourses = useSelector(state => state.userCourses.userCourses);

  const [open, setOpen] = useState(false);
  const [selectedSlug, setSelectedSlug] = useState(null);
  const [urlText, setUrlText] = useState('');
  const [includeStudentAssigned, setIncludeStudentAssigned] = useState(false);
  const [preview, setPreview] = useState(null);
  const [previewError, setPreviewError] = useState(null);

  const source = selectedSlug || urlText.trim();

  useEffect(() => {
    if (open && userCourses.length === 0) {
      dispatch(fetchCoursesForUser(current_user.id));
    }
  }, [open]);

  useEffect(() => {
    setPreview(null);
    setPreviewError(null);
    if (!source) return undefined;

    let cancelled = false;
    const timeout = setTimeout(() => {
      API.previewCopyAvailableArticles({
        course_slug: course_id, source, include_student_assigned: includeStudentAssigned
      })
        .then((resp) => { if (!cancelled) setPreview(resp); })
        .catch((error) => { if (!cancelled) setPreviewError(errorMessageFrom(error)); });
    }, PREVIEW_DEBOUNCE_MS);

    return () => {
      cancelled = true;
      clearTimeout(timeout);
    };
  }, [source, includeStudentAssigned]);

  const options = userCourses
    .filter(userCourse => userCourse.slug !== course.slug)
    .map(userCourse => ({ value: userCourse.slug, label: userCourse.title }));
  const selectedOption = options.find(option => option.value === selectedSlug) || null;

  const onSelectChange = (option) => {
    setSelectedSlug(option ? option.value : null);
    setUrlText('');
  };

  const onUrlChange = (e) => {
    setUrlText(e.target.value);
    setSelectedSlug(null);
  };

  const close = () => {
    setOpen(false);
    setSelectedSlug(null);
    setUrlText('');
    setIncludeStudentAssigned(false);
  };

  const toCopy = preview ? preview.count - preview.already_present : 0;

  const onCopy = () => {
    dispatch(copyAvailableArticles({
      course_slug: course_id, source, include_student_assigned: includeStudentAssigned
    }));
    close();
  };

  const button = (
    <button id="copy-available-articles-button" className="button border small ml2" onClick={() => setOpen(true)}>
      {I18n.t('assignments.copy_available')}
    </button>
  );

  if (!open) return button;

  return (
    <>
      {button}
      <Modal modalClass="confirm-modal-overlay" ariaLabelledBy="copy-available-articles-title">
        <div className="confirm-modal copy-available-articles">
          <h3 id="copy-available-articles-title">{I18n.t('assignments.copy_available')}</h3>
          <div className="copy-available-articles__field">
            <Select
              id="copy-available-articles-source-select"
              inputId="copy-available-articles-source-select-input"
              styles={selectStyles}
              placeholder={I18n.t('assignments.copy_available_select_placeholder')}
              options={options}
              value={selectedOption}
              onChange={onSelectChange}
              isClearable
            />
          </div>
          <div className="copy-available-articles__field">
            <input
              id="copy-available-articles-source-url"
              type="text"
              placeholder={I18n.t('assignments.copy_available_url_placeholder')}
              value={urlText}
              onChange={onUrlChange}
            />
          </div>
          <div className="copy-available-articles__field">
            <input
              id="copy_available_include_student_assigned"
              type="checkbox"
              checked={includeStudentAssigned}
              onChange={e => setIncludeStudentAssigned(e.target.checked)}
            />
            <label htmlFor="copy_available_include_student_assigned">
              {I18n.t('assignments.copy_available_include_student_assigned')}
            </label>
          </div>
          <div className="copy-available-articles__preview">
            {preview && (
              <p>{preview.source.title}: {I18n.t('users.number_of_articles', { count: toCopy })}</p>
            )}
            {previewError && <p className="red">{previewError}</p>}
          </div>
          <div className="pop_container pull-right">
            <button className="button ghost-button" onClick={close}>{I18n.t('application.cancel')}</button>
            <button className="button dark" onClick={onCopy} disabled={toCopy <= 0}>
              {I18n.t('application.confirm')}
            </button>
          </div>
        </div>
      </Modal>
    </>
  );
};

CopyAvailableArticles.propTypes = {
  course: PropTypes.object.isRequired,
  course_id: PropTypes.string.isRequired,
  current_user: PropTypes.object.isRequired
};

export default CopyAvailableArticles;

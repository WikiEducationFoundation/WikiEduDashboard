import React, { useState, useEffect } from 'react';
import PropTypes from 'prop-types';

const EditSandboxUsernameInput = ({ submit, onChange, value, assignment, course }) => {
  const [username, setUsername] = useState('');
  const [previewUrls, setPreviewUrls] = useState({ sandbox: '', bibliography: '', outline: '' });
  const [error, setError] = useState('');

  // Extract current username from existing sandbox URL
  useEffect(() => {
    if (value) {
      try {
        const match = value.match(/\/wiki\/User:([^/]+)\//);
        if (match && match[1]) {
          setUsername(decodeURIComponent(match[1]));
        }
      } catch (e) {
        // Ignore errors in parsing
      }
    }
  }, [value]);

  // Update preview URLs whenever username changes
  useEffect(() => {
    if (username.trim()) {
      const isValid = validateUsername(username);
      if (isValid) {
        const urls = generatePreviewUrls(username);
        setPreviewUrls(urls);
        setError('');
        onChange({ target: { value: urls.sandbox } });
      } else {
        setError(I18n.t('assignments.invalid_username'));
        setPreviewUrls({ sandbox: '', bibliography: '', outline: '' });
      }
    } else {
      setPreviewUrls({ sandbox: '', bibliography: '', outline: '' });
      setError('');
    }
  }, [username]);

  const validateUsername = (name) => {
    // Wikipedia username validation
    // Must not be empty, and should not contain certain characters
    if (!name || name.trim().length === 0) return false;

    // Check for invalid characters: # < > [ ] | { } @ / :
    const invalidChars = /[#<>[\]|{}@/:]/;
    if (invalidChars.test(name)) return false;

    return true;
  };

  const generatePreviewUrls = (newUsername) => {
    // Extract article title from current sandbox URL
    let articleTitle = 'sandbox';
    if (value) {
      const match = value.match(/\/wiki\/User:[^/]+\/(.+)/);
      if (match && match[1]) {
        articleTitle = match[1];
      }
    }

    // Get wiki details from assignment or course
    const language = assignment.language || course?.home_wiki?.language || 'en';
    const project = assignment.project || course?.home_wiki?.project || 'wikipedia';
    const baseUrl = `https://${language}.${project}.org/wiki`;

    const encodedUsername = encodeURIComponent(newUsername.trim());
    const sandbox = `${baseUrl}/User:${encodedUsername}/${articleTitle}`;
    const bibliography = `${baseUrl}/User:${encodedUsername}/${articleTitle}/Bibliography`;
    const outline = `${baseUrl}/User:${encodedUsername}/${articleTitle}/Outline`;

    return { sandbox, bibliography, outline };
  };

  const handleUsernameChange = (e) => {
    setUsername(e.target.value);
  };

  const handleSubmit = (e) => {
    e.preventDefault();
    if (!error && username.trim() && previewUrls.sandbox) {
      submit(e);
    }
  };

  return (
    <form onSubmit={handleSubmit} className="edit-sandbox-username-form">
      <div className="edit-sandbox-instructions">
        <p className="instruction-text">
          {I18n.t('assignments.change_sandbox_instructions')}
        </p>
      </div>

      <div className="input-group">
        <label htmlFor="username-input" className="input-label">
          {I18n.t('assignments.username_label')}
        </label>
        <input
          id="username-input"
          type="text"
          value={username}
          onChange={handleUsernameChange}
          className="edit_sandbox_url_input"
          placeholder={I18n.t('assignments.username_placeholder')}
        />
      </div>

      {error && (
        <div className="error-message">
          {error}
        </div>
      )}

      {!error && previewUrls.sandbox && (
        <div className="preview-section">
          <p className="preview-label">{I18n.t('assignments.preview_label')}</p>
          <div className="preview-urls">
            <div className="preview-url">
              <span className="url-type">{I18n.t('assignments.sandbox_label')}:</span>
              <span className="url-value" title={previewUrls.sandbox}>
                {previewUrls.sandbox}
              </span>
            </div>
            {(assignment.bibliography_sandbox_status || course?.no_sandboxes) && (
              <div className="preview-url">
                <span className="url-type">{I18n.t('assignments.bibliography_label')}:</span>
                <span className="url-value" title={previewUrls.bibliography}>
                  {previewUrls.bibliography}
                </span>
              </div>
            )}
            {(assignment.outline_sandbox_status || course?.no_sandboxes) && (
              <div className="preview-url">
                <span className="url-type">{I18n.t('assignments.outline_label')}:</span>
                <span className="url-value" title={previewUrls.outline}>
                  {previewUrls.outline}
                </span>
              </div>
            )}
          </div>
        </div>
      )}

      <button
        className="button border"
        type="submit"
        disabled={!username.trim() || !!error || !previewUrls.sandbox}
      >
        {I18n.t('assignments.submit')}
      </button>
    </form>
  );
};

EditSandboxUsernameInput.propTypes = {
  submit: PropTypes.func.isRequired,
  onChange: PropTypes.func.isRequired,
  value: PropTypes.string,
  assignment: PropTypes.object.isRequired,
  course: PropTypes.object
};

export default EditSandboxUsernameInput;


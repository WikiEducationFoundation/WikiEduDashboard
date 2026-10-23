/* eslint-disable i18next/no-literal-string */
// English-only research page: no i18n, by decision (see descriptions.js).
import React from 'react';
import PropTypes from 'prop-types';
import { AUTHORSHIP_ID, AUTHORSHIP_NOTE } from './descriptions';

const AuthorshipNote = ({ generatedAt, note = AUTHORSHIP_NOTE }) => (
  <footer className="detector-comparison__footer" id={AUTHORSHIP_ID}>
    <p>{note}</p>
    {generatedAt && <p>Data as of {new Date(generatedAt).toLocaleString()}.</p>}
  </footer>
);

AuthorshipNote.propTypes = { generatedAt: PropTypes.string, note: PropTypes.string };

// The dagger after a heading that points to the authorship note.
export const AuthorshipDagger = () => (
  <sup><a href={`#${AUTHORSHIP_ID}`} className="detector-comparison__dagger" aria-label="Who wrote this section">†</a></sup>
);

export default AuthorshipNote;

/* eslint-disable i18next/no-literal-string */
// English-only research page: no i18n, by decision (see descriptions.js).
import React from 'react';
import PropTypes from 'prop-types';
import { AUTHORSHIP_ID, AUTHORSHIP_NOTE, CREDITS_ID, CREDITS_NOTE } from './descriptions';

const AuthorshipNote = ({ generatedAt, note = AUTHORSHIP_NOTE }) => (
  <footer className="detector-comparison__footer">
    <p id={CREDITS_ID}>{CREDITS_NOTE}</p>
    <p id={AUTHORSHIP_ID}>{note}</p>
    {generatedAt && <p>Data as of {new Date(generatedAt).toLocaleString()}.</p>}
  </footer>
);

AuthorshipNote.propTypes = { generatedAt: PropTypes.string, note: PropTypes.string };

// A footnote mark after a heading, pointing to its note in the footer.
const Dagger = ({ target, symbol, label }) => (
  <sup><a href={`#${target}`} className="detector-comparison__dagger" aria-label={label}>{symbol}</a></sup>
);

Dagger.propTypes = { target: PropTypes.string.isRequired, symbol: PropTypes.string.isRequired, label: PropTypes.string.isRequired };

export const AuthorshipDagger = () => <Dagger target={AUTHORSHIP_ID} symbol="‡" label="Who wrote this section" />;
// After each page's title, pointing to the thanks for donated credits.
export const CreditsDagger = () => <Dagger target={CREDITS_ID} symbol="†" label="Donated credits" />;

export default AuthorshipNote;

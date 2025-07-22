import React from 'react';
import PropTypes from 'prop-types';
import { HashLink as Link } from 'react-router-hash-link';

export const Header = ({ completed = false, course, remaining = [], text }) => (
  <header className="header">
    <h3 className={completed ? 'completed' : ''}>
      {text}
      {remaining.length ? (
        <small>
          {I18n.t('training.remaining_exercise', { count: remaining.length })}
        </small>
      ) : null}
    </h3>
    <Link
      exact="true"
      scroll={el => el.scrollIntoView({ block: 'center' })}
      to={`/courses/${course.slug}/resources#exercises`}
      className="resources-link"
    >
      {I18n.t('training.view_all')}
    </Link>
  </header>
);

Header.propTypes = {
  course: PropTypes.shape({
    slug: PropTypes.string.isRequired,
  }).isRequired,
  remaining: PropTypes.array,
  text: PropTypes.string.isRequired,
};

export default Header;

import React from 'react';
import PropTypes from 'prop-types';
import { HashLink as Link } from 'react-router-hash-link';

export const Header = ({ completed = false, course, remaining = [], text }) => (
  <header className="header">
    <h3 className={completed ? 'completed' : ''}>
<<<<<<< HEAD
      {text}
      {remaining.length ? (
        <small>
          {I18n.t('training.remaining_exercise', { count: remaining.length })}
        </small>
      ) : null}
=======
      { text }
      {
        remaining.length
        ? <small>{remaining.length} additional exercises remaining.</small>
        : null
      }
>>>>>>> f3815a4f0 (Done)
    </h3>
    <Link
      exact="true"
      scroll={el => el.scrollIntoView({ block: 'center' })}
<<<<<<< HEAD
      to={`/courses/${course.slug}/resources#exercises`}
      className="resources-link"
    >
      {I18n.t('training.view_all_exercise')}
=======
      to={`/courses/${course.slug}/resources#exercises`} className="resources-link"
    >
      View all exercises
>>>>>>> f3815a4f0 (Done)
    </Link>
  </header>
);

Header.propTypes = {
  course: PropTypes.shape({
<<<<<<< HEAD
    slug: PropTypes.string.isRequired,
  }).isRequired,
  remaining: PropTypes.array,
  text: PropTypes.string.isRequired,
=======
    slug: PropTypes.string.isRequired
  }).isRequired,
  remaining: PropTypes.array,
  text: PropTypes.string.isRequired
>>>>>>> f3815a4f0 (Done)
};

export default Header;

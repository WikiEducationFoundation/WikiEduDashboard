import React from 'react';
import PropTypes from 'prop-types';

// Components
import SubNavigation from '@components/common/sub_navigation.jsx';

export const StudentsSubNavigation = ({ course, heading, prefix = 'Students' }) => {
  const links = [
    {
      href: `/courses/${course.slug}/students/overview`,
      // Don't forget to change this to conditionally show editors
      text: I18n.t('users.sub_navigation.student_overview', { prefix })
    },
    {
      href: `/courses/${course.slug}/students/articles`,
      text: I18n.t('users.sub_navigation.assignments_and_exercises')
    }
  ];

  return <SubNavigation heading={heading} links={links} />;
};

StudentsSubNavigation.propTypes = {
  course: PropTypes.shape({
    slug: PropTypes.string.isRequired
  }).isRequired,
  heading: PropTypes.string.isRequired
};

export default StudentsSubNavigation;

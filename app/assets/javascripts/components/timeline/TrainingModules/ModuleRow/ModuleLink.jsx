import React from 'react';
import PropTypes from 'prop-types';

export const ModuleLink = ({ iconClassName, link, linkText, module_progress }) => (
  <td className="block__training-modules-table__module-link">
    <a className={module_progress} href={link} target="_blank">
      {linkText}
      <i className={iconClassName} />
    </a>
  </td>
);

ModuleLink.propTypes = {
  iconClassName: PropTypes.string.isRequired,
  link: PropTypes.string.isRequired,
  linkText: PropTypes.string.isRequired,
  module_progress: PropTypes.string
};

export default ModuleLink;

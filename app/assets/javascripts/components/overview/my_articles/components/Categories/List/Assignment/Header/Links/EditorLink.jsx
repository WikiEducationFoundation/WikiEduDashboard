import React from 'react';
import PropTypes from 'prop-types';

import AssignedToLink from '../../../../../../common/AssignedToLink';

export const EditorLink = ({ editors }) => {
  return <AssignedToLink members={editors} name="editors" />;
};

EditorLink.propTypes = {
  // props
  editors: PropTypes.array,
};

export default EditorLink;

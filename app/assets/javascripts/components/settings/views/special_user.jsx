import createReactClass from 'create-react-class';
import PropTypes from 'prop-types';
import React from 'react';

const SpecialUser = createReactClass({
  propTypes: {
    position: PropTypes.string,
    username: PropTypes.string
  },

  render() {
    const username = this.props.username || 'Not Defined';
    return (
      <tr className="user">
        <td className="user__position">
          <p>{this.props.position}</p>
        </td>
        <td className="user__real_name">
          <p>{username}</p>
        </td>
      </tr>
    );
  },
});

export default SpecialUser;

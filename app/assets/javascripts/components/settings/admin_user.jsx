import React from 'react';
class AdminUser extends React.Component {
  render() {
    const { user } = this.props;
    const adminLevel = user.permissions === 3 ?
      'Super Admin' :
      'Admin';
    return (
      <tr className="revision">
        <td>
          <p>{user.username}</p>
        </td>
        <td>
          <p>{user.real_name}</p>
        </td>
        <td>
          <p>{adminLevel}</p>
        </td>
        <td>
          <p>
            <button className="button dark">Revoke Admin Privilages</button>
          </p>

        </td>

      </tr>
    );
  }
}

export default AdminUser;

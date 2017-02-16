import React from 'react';
import EnrollButton from '../students/enroll_button.jsx';

const InlineUsers = React.createClass({
  displayName: 'InlineUsers',

  propTypes: {
    title: React.PropTypes.string,
    role: React.PropTypes.number,
    course: React.PropTypes.object,
    users: React.PropTypes.array,
    current_user: React.PropTypes.object,
    editable: React.PropTypes.bool
  },

  render() {
    const lastUserIndex = this.props.users.length - 1;
    let userList = this.props.users.map((user, index) => {
      let extraInfo;
      const link = `/users/${user.username}`; // User profile page
      if (user.real_name) {
        const email = user.email ? ` / ${user.email}` : '';
        extraInfo = ` (${user.real_name}${email})`;
      } else {
        extraInfo = '';
      }
      if (index !== lastUserIndex) { extraInfo = `${extraInfo}, `; }

      return <span key={user.username}><a href={link}>{user.username}</a>{extraInfo}</span>;
    });
    userList = userList.length > 0 ? userList : I18n.t('courses.none');

    let inlineList;
    if (this.props.users.length > 0 || this.props.editable) {
      inlineList = <span><strong>{this.props.title}:</strong> {userList}</span>;
    }

    const allowed = this.props.role !== 4 || (this.props.current_user.role === 4 || this.props.current_user.admin);
    const button = <EnrollButton {...this.props} users={this.props.users} role={this.props.role} inline={true} allowed={allowed} show={this.props.editable && allowed} />;

    return <div>{inlineList}{button}</div>;
  }
}
);

export default InlineUsers;

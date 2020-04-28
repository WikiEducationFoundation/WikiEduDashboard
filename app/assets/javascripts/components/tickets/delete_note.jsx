import React from 'react';
import { connect } from 'react-redux';
import { deleteNote } from '../../actions/tickets_actions';

class DeleteNote extends React.Component {
      onClick(e) {
            e.preventDefault();
            this.props.deleteNote(this.props.messageId);
      }

      render() {
            return <img src="/assets/images/delete-icon.svg" alt="delete icon" onClick={this.onClick.bind(this)} />;
      }
}

const mapDispatchToProps = {
      deleteNote
};


export default connect(null, mapDispatchToProps)(DeleteNote);

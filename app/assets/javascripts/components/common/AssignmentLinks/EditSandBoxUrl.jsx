import React from 'react';
import { connect } from 'react-redux';
import Popover from '../../common/popover';
import EditSandboxUrlInput from '../../assignments/edit_sandbox_url_input';
import PopoverExpandable from '../../high_order/popover_expandable';
import { updateSandboxUrl } from '../../../actions/assignment_actions';

export class EditSandboxUrl extends React.Component {
constructor(props) {
  super(props);
  this.open = this.open.bind(this);
  this.handleNewUrlChange = this.handleNewUrlChange.bind(this);
  this.submit = this.submit.bind(this);
  this.state = {
    newUrl: '',
  };
}

getKey() {
  let tag = 'open_edit_sandbox_url_input_';
  return tag += this.props.assignment.id;
}

handleNewUrlChange(e) {
  this.setState({
    newUrl: e.target.value,
  });
}

stop(e) {
  e.stopPropagation();
}

open(e) {
  e.preventDefault();
  this.props.open();
  this.setState({
    newUrl: ''
  });
}

submit(e) {
  const { assignment } = this.props;
  this.open(e);
  this.props.updateSandboxUrl(assignment, this.state.newUrl);
}

render() {
  const { is_open } = this.props;
  const editRow = (
    <tr className="edit">
      <td>
        <EditSandboxUrlInput
          submit={this.submit}
          onChange={this.handleNewUrlChange}
          value={this.state.newUrl}
        />
      </td>
    </tr>
  );
    return (
      <>
        <div className="pop__container" onClick={this.stop}>
          <a href="" target="_blank" onClick={this.open}>
            {I18n.t('assignments.edit_sandbox_url')}
          </a>
          <Popover
            is_open={is_open}
            edit_row={editRow}
          />
        </div>
      </>
    );
  }
}

const mapDispatchToProps = {
  updateSandboxUrl,
};

export default connect(null, mapDispatchToProps)(PopoverExpandable(EditSandboxUrl));

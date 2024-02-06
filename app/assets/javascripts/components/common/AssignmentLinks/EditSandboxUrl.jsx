import React from 'react';
import { connect } from 'react-redux';
import Popover from '../../common/popover';
import EditSandboxUrlInput from '../../assignments/edit_sandbox_url_input';
import PopoverExpandable from '../../high_order/popover_expandable';
import { updateSandboxUrl } from '../../../actions/assignment_actions';

export class EditSandboxUrl extends React.Component {
constructor(props) {
  super(props);
  this.toggle = this.toggle.bind(this);
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

toggle(e) {
  e.preventDefault();
  this.props.open();
  this.setState({
    newUrl: ''
  });
}

submit(e) {
  if (this.state.newUrl !== '') {
    const { assignment } = this.props;
    this.toggle(e);
    this.props.updateSandboxUrl(assignment, this.state.newUrl);
  } else {
    e.preventDefault();
  }
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
  if (is_open) {
    return (
      <div className="pop__container edit_sandBox" onClick={this.stop}>
        <Popover
          is_open={is_open}
          edit_row={editRow}
        />
      </div>
    );
  }
    return (
      <>
        <a href="" target="_blank" onClick={this.toggle} className="change-sandbox-url">
          ({I18n.t('assignments.change_sandbox_url')})
        </a>
      </>
    );
  }
}

const mapDispatchToProps = {
  updateSandboxUrl,
};

export default connect(null, mapDispatchToProps)(PopoverExpandable(EditSandboxUrl));

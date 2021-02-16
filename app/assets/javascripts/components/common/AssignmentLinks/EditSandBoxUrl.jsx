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
}

getKey() {
  let tag = 'open_sandbox_url_input_';
  return tag += this.props.assignment.id;
}

stop(e) {
  e.stopPropagation();
}

open() {
  this.props.open();
}

submit(e, newUrl) {
  e.preventDefault();
  const { assignment } = this.props;
  this.open();
  this.props.updateSandboxUrl(assignment, newUrl);
}
render() {
  const { is_open } = this.props;
  const editRow = (
    <tr className="edit">
      <td>
        <EditSandboxUrlInput submit={this.submit.bind(this)} />
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

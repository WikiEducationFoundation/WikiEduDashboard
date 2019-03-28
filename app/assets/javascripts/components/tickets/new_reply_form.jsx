import React from 'react';

import TextAreaInput from '../common/text_area_input.jsx';

export class NewReplyForm extends React.Component {
  constructor() {
    super();
    this.state = {
      replyText: null
    };
  }

  onChange(val) {
    this.setState({ replyText: val });
  }

  render() {
    return (
      <form>
        <h3>Send a Reply</h3>
        <div className="bg-white">
          <TextAreaInput
            id="reply"
            editable
            label="Enter your reply"
            value_key="reply"
            wysiwyg={true}
            onChange={this.onChange.bind(this)}
          />
        </div>
        <button className="button dark right mt2">Send Reply</button>
      </form>
    );
  }
}

export default NewReplyForm;

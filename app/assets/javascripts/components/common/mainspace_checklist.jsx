import React from 'react';
import createReactClass from 'create-react-class';
import OnClickOutside from 'react-onclickoutside';

const MainspaceChecklist = createReactClass({
  displayName: 'MainspaceChecklist',

  getInitialState() {
    return {
      show: false
    };
  },

  show() {
    this.setState({ show: true });
  },

  hide() {
    this.setState({ show: false });
  },

  handleClickOutside() {
    this.hide();
  },

  render() {
    let button;
    if (this.state.show) {
      button = <button onClick={this.hide} className="button dark small">Okay</button>;
    } else {
      button = <a onClick={this.show} className="button dark small">Ready for mainspace checklist</a>;
    }

    let modal;
    if (!this.state.show) {
      modal = <div className="empty" />;
    } else {
      modal = (
        <div className="article-viewer my-assignment-checklist">
          <h2>Mainspace checklist</h2>
          <p>
            Before you move your draft into mainspace and make it a live Wikipedia
            article, make sure it&apos;s ready.
          </p>
          <dl>
            <dd><input type="checkbox" /> It starts with a clear definition of the topic, with the title in the first sentence in <strong>bold</strong>.</dd>
            <dd><input type="checkbox" /> It has a lead section — which comes before any section headers — that provides an overview of the topic.</dd>
            <dd><input type="checkbox" /> If it has additional sections after the lead, they have content, not just a placeholder.</dd>
            <dd><input type="checkbox" /> The content has inline citations, not just a bibliography.</dd>
            <dd><input type="checkbox" /> It has a &quot;References&quot; section after the body of the article.</dd>
            <dd><input type="checkbox" /> You have removed all comments, notes, and outlines from the draft.</dd>
          </dl>
          {button}
        </div>
      );
    }

    return (
      <div>
        {button}
        {modal}
      </div>
    );
  }
});

export default OnClickOutside(MainspaceChecklist);

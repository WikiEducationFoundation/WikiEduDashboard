import React from 'react';
import createReactClass from 'create-react-class';
import OnClickOutside from 'react-onclickoutside';

const FinalArticleChecklist = createReactClass({
  displayName: 'FinalArticleChecklist',

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
      button = <a onClick={this.show} className="button dark small">Quality checklist</a>;
    }

    let modal;
    if (!this.state.show) {
      modal = <div className="empty" />;
    } else {
      modal = (
        <div className="article-viewer my-assignment-checklist">
          <h2>Final review checklist</h2>
          <p>
            As you polish up your completed article, review each of these items and fix any problems you find.
          </p>
          <dl>
            <dd><input type="checkbox" /> The title short and simple. It doesn’t look like an essay, or ask a question.</dd>
            <dd><input type="checkbox" /> The first sentence is direct and useful; it clearly defines the subject, with the topic of the article in bold.</dd>
            <dd><input type="checkbox" /> The lead section is a clear summary, not an introduction or argument. A reader could stop at the end of the lead and have a good overview of the most important aspects of the topic.</dd>
            <dd><input type="checkbox" /> It doesn’t contain excessive quotations, or copy any sources (even if you’ve given them credit).</dd>
            <dd><input type="checkbox" /> The writing is clear to a non-expert; you’ve explained acronyms and jargon in simple English the first time you use them.</dd>
            <dd><input type="checkbox" /> It lets readers decide for themselves, without any persuasive language that aims to sway a reader to a conclusion.</dd>
            <dd><input type="checkbox" /> You&apos;ve proof-read it all the way through. Grammar and spelling are correct, sentences are complete sentences, and there is no first-person (“I/we”) or second-person (“you”) writing.</dd>
            <dd><input type="checkbox" /> The formatting is consistent with the rest of Wikipedia, without too many headings. Bulleted lists are used sparingly or not at all.</dd>
            <dd><input type="checkbox" /> Every claim is cited to a reliable source — like a textbook or academic journal — and it doesn&apos;t cite any blog posts.</dd>
            <dd><input type="checkbox" /> The text includes links other Wikipedia articles the first time each relevant topic is mentioned.</dd>
            <dd><input type="checkbox" /> At least one related Wikipedia article links back to this one.</dd>
            <dd><input type="checkbox" /> You&apos;ve thanked people who helped you. Check your User Talk page, and the Talk page of your article. If anyone offered help or feedback, say thanks!</dd>
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

export default OnClickOutside(FinalArticleChecklist);

import React from 'react';
import OnClickOutside from 'react-onclickoutside';

const EditingSuggestions = React.createClass({
  displayName: 'EditingSuggestions',

  propTypes: {
    assignment: React.PropTypes.object.isRequired
  },

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
      button = <a onClick={this.show} className="button dark small">{I18n.t('suggestions.editing')}</a>;
    }

    let modal;
    if (!this.state.show) {
      modal = <div className="empty" />;
    } else {
      modal = (
        <div className="article-viewer suggestions">
          <h2>Editing Suggestions</h2>
          <p>
            {I18n.t(`suggestions.suggestion_docs.${this.props.assignment.article_rating || '?'}`)}
          </p>
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

export default OnClickOutside(EditingSuggestions);

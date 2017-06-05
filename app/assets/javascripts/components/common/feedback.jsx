import React from 'react';
import OnClickOutside from 'react-onclickoutside';
import { bindActionCreators } from 'redux';
import { connect } from 'react-redux';
import * as FeedbackAction from '../../actions/feedback_action.js';

const Feedback = React.createClass({
  displayName: 'Feedback',

  propTypes: {
    fetchFeedback: React.PropTypes.func,
    feedback: React.PropTypes.object,
    assignment: React.PropTypes.object.isRequired
  },

  getInitialState() {
    return {
      show: false
    };
  },

  componentWillMount() {
    if (this.props.assignment.article_id) {
      this.props.fetchFeedback(this.props.assignment.article_id);
    }
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
      button = <a onClick={this.show} className="button dark small">{I18n.t('courses.feedback')}</a>;
    }

    let modal;
    let messages = this.props.feedback[this.props.assignment.article_id];
    const feedbackList = [];
    if (!messages) {
      messages = [{ message: 'The Article doesn\'t exist' }];
    }

    for (let i = 0; i < messages.length; i++) {
      feedbackList.push(<li>{messages[i].message}</li>);
    }
    if (!this.state.show) {
      modal = <div className="empty" />;
    } else {
      modal = (
        <div className="article-viewer feedback">
          <h2>Feedback</h2>
          <a className="button small diff-viewer-feedback" href="" target="_blank">{I18n.t('courses.suggestions_feedback')}</a>
          <ul>
            {feedbackList}
          </ul>
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

const mapDispatchToProps = dispatch => ({
  fetchFeedback: bindActionCreators(FeedbackAction, dispatch).fetchFeedback
});

const mapStateToProps = state => ({
  feedback: state.feedback
});

export default connect(mapStateToProps, mapDispatchToProps)(OnClickOutside(Feedback));

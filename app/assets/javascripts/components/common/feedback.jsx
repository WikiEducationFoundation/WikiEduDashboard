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
    this.props.fetchFeedback(this.props.assignment.article_title);
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
    const titleParam = this.props.assignment.article_title;
    const feedbackLink = `/feedback?main_subject=Revision Feedback&subject=/revision_feedback?title=${titleParam}`;

    if (this.state.show) {
      button = <button onClick={this.hide} className="button dark small">Okay</button>;
    } else {
      button = <a onClick={this.show} className="button dark small">{I18n.t('courses.feedback')}</a>;
    }
    const feedbackButton = (<a className="button small" href={feedbackLink} target="_blank">{I18n.t('courses.suggestions_feedback')}</a>);

    let modal;

    const data = this.props.feedback[titleParam];
    let rating = '';
    let messages = [];
    const feedbackList = [];
    let feedbackBody = (
      <div className="feedback-body">
        <p>{I18n.t('courses.feedback_loading')}</p>
      </div>
    );

    if (data) {
      messages = data.suggestions;
      rating = data.rating;

      for (let i = 0; i < messages.length; i++) {
        feedbackList.push(<li key={i.toString()}>{messages[i].message}</li>);
      }
      if (rating != null) {
        feedbackBody = (
          <div className="feedback-body">
            <h5>{I18n.t('courses.rating_feedback') + rating}</h5>
            <p>
              {I18n.t(`suggestions.suggestion_docs.${rating.toLowerCase() || '?'}`)}
            </p>
            <h5>{I18n.t('courses.features_feedback')}</h5>
            <ul>
              {feedbackList}
            </ul>
          </div>
        );
      } else {
        feedbackBody = (
          <div className="feedback-body">
            <p>{I18n.t('courses.does_not_exist')}</p>
          </div>
        );
      }
    }

    if (!this.state.show) {
      modal = <div className="empty" />;
    } else {
      modal = (
        <div className="article-viewer feedback">
          <h2>Feedback</h2>
          {feedbackButton}
          {feedbackBody}
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

import React from 'react';
import OnClickOutside from 'react-onclickoutside';
import { bindActionCreators } from 'redux';
import { connect } from 'react-redux';
import * as FeedbackAction from '../../actions/feedback_action.js';
import API from '../../utils/api.js';
const Feedback = React.createClass({
  displayName: 'Feedback',

  propTypes: {
    fetchFeedback: React.PropTypes.func,
    feedback: React.PropTypes.object,
    assignment: React.PropTypes.object.isRequired,
    username: React.PropTypes.string
  },

  getInitialState() {
    return {
      show: false,
      fetched: false,
      feedbackSent: false
    };
  },

  titleParam() {
    if (this.props.assignment.article_id) {
      return this.props.assignment.article_title;
    }
    return `User:${this.props.username}/sandbox`;
  },

  show() {
    this.setState({ show: true });
    if (!this.state.fetched) {
      this.props.fetchFeedback(this.titleParam());
      this.setState({ fetched: true });
    }
  },

  hide() {
    this.setState({ show: false });
  },

  handleClickOutside() {
    this.hide();
  },

  handleSubmit(event) {
    const subject = `/revision_feedback?title=${this.titleParam()}`;
    const body = this.input.value;
    this.setState({ feedbackSent: 'sending' });
    API.postFeedbackFormResponse(subject, body).then(() => {
      this.setState({ feedbackSent: true });
    }, () => {
      this.setState({ feedbackSent: false });
      alert(I18n.t('courses.suggestions_failed'));
    });
    event.preventDefault();
  },

  render() {
    let button;
    const titleParam = this.titleParam();
    if (this.state.show) {
      button = <button onClick={this.hide} className="okay icon-close"></button>;
    } else {
      button = <a onClick={this.show} className="button dark small">{I18n.t('courses.feedback')}</a>;
    }

    let submitFeedback;
    if (this.state.feedbackSent === true) {
      submitFeedback = I18n.t('courses.suggestions_sent');
    } else if (this.state.feedbackSent === 'sending') {
      submitFeedback = I18n.t('courses.suggestions_sending');
    } else {
      submitFeedback = <input className="button dark small" type="submit" value="Submit" />;
    }

    let modal;

    const data = this.props.feedback[titleParam];
    let rating = '';
    let messages = [];
    const feedbackList = [];
    let titleElement;
    let feedbackBody = (
      <div className="feedback-body">
        <p>{I18n.t('courses.feedback_loading')}</p>
      </div>
    );
    let feedbackForm;

    if (this.props.assignment.article_id) {
      titleElement = <a className="my-assignment-title" target="_blank" href={this.props.assignment.article_url}>{this.props.assignment.article_title}</a>;
    } else {
      titleElement = <a className="my-assignment-title" target="_blank" href={`https://en.wikipedia.org/wiki/User:${this.props.username}/sandbox`}>{`User:${this.props.username}/sandbox`}</a>;
    }

    if (data) {
      messages = data.suggestions;
      rating = data.rating;

      for (let i = 0; i < messages.length; i++) {
        feedbackList.push(<li key={i.toString()}>{messages[i].message}</li>);
      }
      feedbackForm = (
        <form onSubmit={this.handleSubmit}>
          <textarea className="feedback-form" rows="1" cols="150" ref={(input) => this.input = input} placeholder={I18n.t('courses.suggestions_feedback')} />
          {submitFeedback}
        </form>
      );

      if (rating != null) {
        feedbackBody = (
          <div className="feedback-body">
            {titleElement}
            <hr />
            <h5>{I18n.t('courses.rating_feedback') + rating}</h5>
            <p className="rating-description">
              {I18n.t(`articles.rating_docs.${rating.toLowerCase() || '?'}`)}
            </p>
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
          {button}
          <h2>Feedback</h2>
          {feedbackBody}
          {feedbackForm}
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

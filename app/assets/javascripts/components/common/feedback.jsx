
import React from 'react';
import createReactClass from 'create-react-class';
import PropTypes from 'prop-types';
import OnClickOutside from 'react-onclickoutside';
import { bindActionCreators } from 'redux';
import { connect } from 'react-redux';
import * as FeedbackAction from '../../actions/feedback_action.js';
import API from '../../utils/api.js';
const Feedback = createReactClass({
  displayName: 'Feedback',

  propTypes: {
    fetchFeedback: PropTypes.func,
    postUserFeedback: PropTypes.func,
    current_user: PropTypes.object,
    deleteUserFeedback: PropTypes.func,
    feedback: PropTypes.object,
    assignment: PropTypes.object.isRequired,
    username: PropTypes.string
  },

  getInitialState() {
    return {
      show: false,
      fetched: false,
      feedbackSent: false,
      feedbackInput: '',
      showFeedbackForm: false
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
      this.props.fetchFeedback(this.titleParam(), this.props.assignment.id);
      this.setState({ fetched: true });
    }
  },

  showFeedbackInput() {
    this.setState({ showFeedbackForm: true });
  },

  hide() {
    this.setState({ show: false });
  },

  handleClickOutside() {
    this.hide();
  },

  handleFeedbackInputChange(event) {
    this.setState({ feedbackInput: event.target.value });
  },

  handleFeedbackSubmit(event) {
    const feedback = this.state.feedbackInput;
    this.setState({ feedbackInput: '' });
    this.props.postUserFeedback(this.props.assignment.id, feedback, this.props.current_user.id);
    event.preventDefault();
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

  handleRemove(id, arrayId) {
    this.props.deleteUserFeedback(this.props.assignment.id, id, arrayId);
  },

  render() {
    // Title set based on if the article exists in mainspace
    let button;
    if (this.state.show) {
      button = <button onClick={this.hide} className="okay icon-close" />;
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
    const data = this.props.feedback[this.props.assignment.id];
    let rating = '';
    let messages = [];
    let customMessages = [];
    const feedbackList = [];
    const userSuggestionList = [];
    let titleElement;
    let feedbackBody = (
      <div className="feedback-body">
        <p>{I18n.t('courses.feedback_loading')}</p>
      </div>
    );

    let feedbackForm;
    let feedbackButton;
    let customSuggestionsForm;

    if (this.props.assignment.article_id) {
      titleElement = <a className="my-assignment-title" target="_blank" href={this.props.assignment.article_url}>{this.props.assignment.article_title}</a>;
    } else {
      titleElement = <a className="my-assignment-title" target="_blank" href={`https://en.wikipedia.org/wiki/User:${this.props.username}/sandbox`}>{`User:${this.props.username}/sandbox`}</a>;
    }

    if (data) {
      messages = data.suggestions;
      rating = data.rating;
      customMessages = data.custom;

      for (let i = 0; i < messages.length; i++) {
        feedbackList.push(<li key={i.toString()}>{messages[i].message}</li>);
      }

      if (!this.state.showFeedbackForm) {
        feedbackButton = <a onClick={this.showFeedbackInput} className="button dark">{I18n.t('courses.suggestions_feedback')}</a>;
      }
      else {
        feedbackForm = (
          <form onSubmit={this.handleSubmit}>
            <textarea className="feedback-form" rows="1" cols="150" ref={(input) => this.input = input} placeholder={I18n.t('courses.suggestions_feedback')} />
            {submitFeedback}
          </form>
        );
      }

      let automatedSuggestions;
      if (messages.length > 0) {
        automatedSuggestions = (
          <div>
            <p>
              {I18n.t(`suggestions.suggestion_docs.${rating.toLowerCase() || '?'}`)}
            </p>
            <h5>{I18n.t('courses.features_feedback')}</h5>
            <ul>
              {feedbackList}
            </ul>
            {feedbackButton}
            {feedbackForm}<br />
          </div>
        );
      }

      for (let i = 0; i < customMessages.length; i++) {
        let deleteButton;
        if (customMessages[i].userId === this.props.current_user.id) {
          deleteButton = <a className="button dark small" onClick={() => this.handleRemove(customMessages[i].messageId, i)}>{I18n.t('courses.delete_suggestion')}</a>;
        }
        userSuggestionList.push(<li key={customMessages[i].messageId}> {customMessages[i].message} {deleteButton} </li>);
      }

      // Input box to input custom feedback
      customSuggestionsForm = (
        <form onSubmit={this.handleFeedbackSubmit}>
          <textarea className="feedback-form" rows="1" cols="150" onChange={this.handleFeedbackInputChange} value={this.state.feedbackInput} placeholder={I18n.t('courses.user_suggestions_prompt')} />
          <input className="button dark small" type="submit" value="Add Suggestion" />
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
            {automatedSuggestions}
            <h5>{I18n.t('courses.user_suggestions')}</h5>
            <ul>
              {userSuggestionList}
            </ul>
            {customSuggestionsForm}
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
  fetchFeedback: bindActionCreators(FeedbackAction, dispatch).fetchFeedback,
  postUserFeedback: bindActionCreators(FeedbackAction, dispatch).postUserFeedback,
  deleteUserFeedback: bindActionCreators(FeedbackAction, dispatch).deleteUserFeedback
});

const mapStateToProps = state => ({
  feedback: state.feedback
});

export default connect(mapStateToProps, mapDispatchToProps)(OnClickOutside(Feedback));

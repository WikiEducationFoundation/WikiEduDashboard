import React, { useState, useRef } from 'react';
import PropTypes from 'prop-types';
import { useDispatch, useSelector } from 'react-redux';
import { fetchFeedback, postUserFeedback, deleteUserFeedback } from '../../actions/feedback_action.js';
import API from '../../utils/api.js';
import useOutsideClick from '../../hooks/useOutsideClick.js';

const Feedback = ({ assignment, username, current_user }) => {
  const [show, setShow] = useState(false);
  const [fetched, setFetched] = useState(false);
  const [feedbackSent, setFeedbackSent] = useState(false);
  const [feedbackInput, setFeedbackInput] = useState('');
  const [showFeedbackForm, setShowFeedbackForm] = useState(false);
  const inputRef = useRef(null);

  const dispatch = useDispatch();
  const feedback = useSelector(state => state.feedback);

  const hide = () => {
    setShow(false);
  };
  const ref = useOutsideClick(hide);

  const titleParam = () => {
    if (assignment.article_id) {
      return assignment.article_title;
    }
    return `User:${username}/sandbox`;
  };

  const handleFeedbackInputChange = (event) => {
    setFeedbackInput(event.target.value);
  };

  const handleFeedbackSubmit = (event) => {
    const givenFeedback = feedbackInput;
    setFeedbackInput('');
    dispatch(postUserFeedback(assignment.id, givenFeedback, current_user.id));
    event.preventDefault();
  };

  const handleSubmit = (event) => {
    const subject = `/revision_feedback?title=${titleParam()}`;
    const body = inputRef.current.value;
    setFeedbackSent('sending');
    API.postFeedbackFormResponse(subject, body).then(() => {
      setFeedbackSent(true);
    }, () => {
      setFeedbackSent(false);
      alert(I18n.t('courses.suggestions_failed'));
    });
    event.preventDefault();
  };

  const handleRemove = (id, arrayId) => {
    dispatch(deleteUserFeedback(assignment.id, id, arrayId));
  };

  const showFeedbackInput = () => {
    setShowFeedbackForm(true);
  };

  const showHandler = () => {
    setShow(true);
    if (!fetched) {
      dispatch(fetchFeedback(titleParam(), assignment.id));
      setFetched(true);
    }
  };

  let button;
  if (show) {
    button = <div className="feedback-close-container"><button onClick={hide} className="feedback-close icon-close" /></div>;
  } else {
    button = <a onClick={showHandler} className="button dark small">{I18n.t('courses.feedback')}</a>;
  }

  let submitFeedback;
  if (feedbackSent === true) {
    submitFeedback = I18n.t('courses.suggestions_sent');
  } else if (feedbackSent === 'sending') {
    submitFeedback = I18n.t('courses.suggestions_sending');
  } else {
    submitFeedback = <input className="button dark small" type="submit" value="Submit" />;
  }

  let modal;
  const data = feedback[assignment.id];
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

  if (assignment.article_id) {
    titleElement = <a className="my-assignment-title" target="_blank" href={assignment.article_url}>{assignment.article_title}</a>;
  } else {
    titleElement = <a className="my-assignment-title" target="_blank" href={`https://en.wikipedia.org/wiki/User:${username}/sandbox`}>{`User:${username}/sandbox`}</a>;
  }

  if (data) {
    messages = data.suggestions;
    rating = data.rating;
    customMessages = data.custom;

    for (let i = 0; i < messages.length; i += 1) {
      feedbackList.push(<li key={i.toString()}>{messages[i].message}</li>);
    }

    if (!showFeedbackForm) {
      feedbackButton = <a onClick={showFeedbackInput} className="button dark">{I18n.t('courses.suggestions_feedback')}</a>;
    } else {
      feedbackForm = (
        <form onSubmit={handleSubmit}>
          <textarea className="feedback-form" rows="1" cols="150" ref={inputRef} placeholder={I18n.t('courses.suggestions_feedback')} />
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

    for (let i = 0; i < customMessages.length; i += 1) {
      let deleteButton;
      if (customMessages[i].userId === current_user.id) {
        deleteButton = <a style={{ marginLeft: '20px' }} className="button dark small" onClick={() => handleRemove(customMessages[i].messageId, i)}>{I18n.t('courses.delete_suggestion')}</a>;
      }
      userSuggestionList.push(<li key={customMessages[i].messageId}> {customMessages[i].message} {deleteButton} </li>);
    }

    // Input box to input custom feedback
    customSuggestionsForm = (
      <form onSubmit={handleFeedbackSubmit} className="feedback-form-container">
        <textarea className="feedback-form" rows="1" cols="150" onChange={handleFeedbackInputChange} value={feedbackInput} placeholder={I18n.t('courses.user_suggestions_prompt')} />
        <input className="button dark small" type="submit" value="Add Suggestion" />
      </form>
    );

    if (rating != null) {
      feedbackBody = (
        <div className="feedback-body">
          {titleElement}
          <hr />
          <h5>{`${I18n.t('courses.rating_feedback')} ${rating}`}</h5>
          <p className="rating-description">
            {I18n.t(`articles.rating_docs.${rating.toLowerCase() || '?'}`, { class: rating.toLowerCase() || '' })}
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

  if (!show) {
    modal = <div className="empty" />;
  } else {
    modal = (
      <div className="article-viewer feedback" ref={ref}>
        {button}
        <h2>{I18n.t('courses.feedback')}</h2>
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
};

Feedback.propTypes = {
  assignment: PropTypes.object.isRequired,
  username: PropTypes.string.isRequired
};

export default Feedback;

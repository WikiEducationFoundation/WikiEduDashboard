import React, { useState } from 'react';
import PropTypes from 'prop-types';
import { initiateConfirm } from '../../actions/confirm_actions.js';
import TextAreaInput from '@components/common/text_area_input.jsx';
import { useDispatch } from 'react-redux';
import Loading from '@components/common/loading.jsx';
import API from '../../utils/api.js';
import { ADD_NOTIFICATION } from '../../constants/notifications.js';

NotifyInstructorsButton.propTypes = {
  courseId: PropTypes.number.isRequired,
  courseTitle: PropTypes.string.isRequired,
};

const initialState = {
  message: '',
  status: 'DEFAULT', // DEFAULT, PENDING, FAILED
  error: null
 };

export default function NotifyInstructorsButton(props) {
  const dispatch = useDispatch();

  const [modalVisibility, setModalVisibility] = useState(false);
  const [notification, setNotification] = useState(initialState);

  const createNotificationApi = () => {
    setNotification({ ...notification, status: 'PENDING' });
    API.createInstructorNotificationAlert(props.courseId, notification.message.trim())
    .then(() => {
      setNotification({ ...initialState });
      setModalVisibility(false);
      dispatch({ type: ADD_NOTIFICATION,
        notification: {
              message: `Notification sent to All Instructors of Course ${props.courseTitle}`,
              closable: true,
              type: 'success'
            } });
    })
    .catch((resp) => {
      // failed
      const msg = resp.readyState === 0 ? 'Unable to send request. Check if you are connected to Internet' : `Server Error : Unable to send notification (${resp.status} ${resp.statusText})`;
      setNotification({ ...notification, status: 'FAILED', error: msg });
    });
  };

  const sendNotificationHandler = () => {
    if (!notification.message) {
      setNotification({ ...notification, status: 'FAILED', error: 'Message cannot be empty' });
      return;
    }

    dispatch(initiateConfirm({
      confirmMessage: 'Are you sure you want to send the notification to all the Instructors',
      onConfirm: createNotificationApi,
    }));
  };

  return (
    <>
      <button onClick={() => setModalVisibility(!modalVisibility)} className="button">
        {I18n.t('courses.notify_instructors')}
      </button>

      {
        modalVisibility && (
        <div className="basic-modal course-stats-download-modal">
          <button onClick={() => setModalVisibility(false)} className="pull-right article-viewer-button icon-close" />
          <h2>{I18n.t('courses.notify_instructors')}</h2>
          <p>
            {I18n.t('courses.notify_instructors_feature_description')}
          </p>
          <hr />

          {
            notification.status === 'FAILED' && <div className="notice--error">{notification.error}</div>
          }

          <TextAreaInput
            id={'notification-message'}
            onChange={(_key, value) => {
              setNotification((prevNotification) => {
                return { ...prevNotification, message: value };
              });
            }}
            value={notification.message}
            value_key="notification_message"
            editable
            placeholder={'Write Message Here'}
          />

          {
            (notification.status === 'PENDING')
            ? <Loading text="Sending Notification to Instructors" />
            : <button className="button border pull-right mt1" onClick={sendNotificationHandler}>{I18n.t('courses.send_notification_button_text')}</button>
          }
        </div>
        )
      }

    </>
  );
}

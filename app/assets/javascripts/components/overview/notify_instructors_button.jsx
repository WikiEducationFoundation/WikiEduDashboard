import React, { useState } from 'react';
import PropTypes from 'prop-types';
import { initiateConfirm } from '../../actions/confirm_actions.js';
import TextAreaInput from '@components/common/text_area_input.jsx';
import { useDispatch } from 'react-redux';
import Loading from '@components/common/loading.jsx';
import API from '../../utils/api.js';
import { ADD_NOTIFICATION } from '../../constants/notifications.js';
import TextInput from '@components/common/text_input.jsx';

NotifyInstructorsButton.propTypes = {
  courseId: PropTypes.number.isRequired,
  courseTitle: PropTypes.string.isRequired,
};

const initialState = {
  subject: '',
  message: '',
  status: 'DEFAULT', // DEFAULT, PENDING, FAILED
  error: null,
};

export default function NotifyInstructorsButton(props) {
  const dispatch = useDispatch();

  const [modalVisibility, setModalVisibility] = useState(false);
  const [notification, setNotification] = useState(initialState);

  const createNotificationApi = () => {
    setNotification({ ...notification, status: 'PENDING' });
    API.createInstructorNotificationAlert(props.courseId, notification.subject.trim(), notification.message.trim())
      .then(() => {
        setNotification({ ...initialState });
        setModalVisibility(false);
        dispatch({
          type: ADD_NOTIFICATION,
          notification: {
            message: I18n.t('course_instructor_notification.notification_sent_success', { courseTitle: props.courseTitle }),
            closable: true,
            type: 'success',
          },
        });
      })
      .catch((resp) => {
        // failed
        const msg = resp.readyState === 0
            ? I18n.t('course_instructor_notification.notification_send_error_no_internet')
            : I18n.t('course_instructor_notification.notification_send_error_server', {
                status: resp.status,
                statusText: resp.statusText,
              });
        setNotification({ ...notification, status: 'FAILED', error: msg });
      });
  };

  const sendNotificationHandler = () => {
    if (!notification.message) {
      setNotification({ ...notification, status: 'FAILED', error: I18n.t('course_instructor_notification.notification_empty_message') });
      return;
    }

    dispatch(
      initiateConfirm({
        confirmMessage: I18n.t('course_instructor_notification.confirm_send_notification'),
        onConfirm: createNotificationApi,
      })
    );
  };

  return (
    <>
      <button onClick={() => setModalVisibility(!modalVisibility)} className="button">
        {I18n.t('course_instructor_notification.notify_instructors')}
      </button>

      {modalVisibility && (
        <div className="basic-modal course-stats-download-modal">
          <button onClick={() => setModalVisibility(false)} className="pull-right article-viewer-button icon-close" />
          <h2>{I18n.t('course_instructor_notification.notify_instructors')}</h2>
          <p>{I18n.t('course_instructor_notification.notify_instructors_feature_description')}</p>
          <hr />

          {notification.status === 'FAILED' && <div className="notice--error">{notification.error}</div>}

          <TextInput
            placeholder={I18n.t('course_instructor_notification.write_subject')}
            editable
            value={notification.subject}
            onChange={(_, value) => {
              setNotification((prevNotification) => {
                return { ...prevNotification, subject: value };
              });
            }}
          />

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
            placeholder={I18n.t('course_instructor_notification.write_message_placeholder')}
          />

          {notification.status === 'PENDING' ? (
            <Loading text={I18n.t('course_instructor_notification.sending_notification')} />
          ) : (
            <button className="button border pull-right mt1" onClick={sendNotificationHandler}>
              {I18n.t('course_instructor_notification.send_notification_button_text')}
            </button>
          )}
        </div>
      )}
    </>
  );
}

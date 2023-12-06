import React, { useState } from 'react';
import PropTypes from 'prop-types';
// import { connect } from 'react-redux';
// import { cloneCourse } from '../../actions/course_creation_actions.js';
// import { initiateConfirm } from '../../actions/confirm_actions.js';
// import { updateCourse } from '../../actions/course_actions.js';
import TextAreaInput from '@components/common/text_area_input.jsx';

NotifyInstructorsButton.propTypes = {
  courseId: PropTypes.number.isRequired,
};

// eslint-disable-next-line no-unused-vars
export function NotifyInstructorsButton(props) {
  const [modalVisibility, setModalVisibility] = useState(false);
  const [notification, setNotification] = useState({
    message: ''
  });

  const sendNotificationHandler = () => {
    // props.courseId = '';
    // eslint-disable-next-line no-console
    console.debug(notification);
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

          <button className="button border pull-right mt1" onClick={sendNotificationHandler}>{I18n.t('courses.send_notification_button_text')}</button>
        </div>
        )
      }

    </>
  );
}

export default NotifyInstructorsButton;

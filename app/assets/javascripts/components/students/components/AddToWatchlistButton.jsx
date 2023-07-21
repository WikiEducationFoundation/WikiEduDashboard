import React from 'react';
import { useDispatch } from 'react-redux';
import { initiateConfirm } from '@actions/confirm_actions';
import { ADD_NOTIFICATION } from '~/app/assets/javascripts/constants/index';
import request from '~/app/assets/javascripts/utils/request';
import logErrorMessage from '~/app/assets/javascripts/utils/log_error_message';

const AddToWatchlistButton = ({ slug, prefix = 'Students' }) => {
  const notificationMessage = (type) => {
    return {
      message: I18n.t(`users.sub_navigation.watch_list.${type === 'Success' ? 'success_message' : 'error_message'}`,
      { prefix }
     ),
      closable: true,
      type: type === 'Success' ? 'success' : 'error'
    };
 };

 const addToWatchlist = () => {
    request(`/courses/${slug}/students/add_to_watchlist`, { method: 'POST' })
     .then(res => res.json())
     .then((data) => {
        if (data.message.batchcomplete) {
        dispatch({ type: ADD_NOTIFICATION, notification: notificationMessage('Success') });
        } else {
          return Promise.reject(data);
        }
     })
      .catch((error) => {
        dispatch({ type: ADD_NOTIFICATION, notification: notificationMessage('error') });
        logErrorMessage(error);
        return error;
      });
  };

  const dispatch = useDispatch();

  const addToWatchlistHandler = () => {
    const onConfirm = () => {
      addToWatchlist();
    };
    const confirmMessage = I18n.t('users.sub_navigation.watch_list.instructional_message');
    dispatch(initiateConfirm({ confirmMessage, onConfirm }));
  };

  return (
    <div className="tooltip-trigger">
      <button className="button border small watchlist-button" onClick={addToWatchlistHandler}>
        {I18n.t('users.sub_navigation.watch_list.students_add', { prefix })} {<span className="tooltip-indicator" />}
      </button>
      <div className="tooltip">
        <p>
          {I18n.t('users.sub_navigation.watch_list.tooltip_message')}
        </p>
      </div>
    </div>
  );
};

export default AddToWatchlistButton;

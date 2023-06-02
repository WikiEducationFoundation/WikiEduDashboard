import React from 'react';
import { useDispatch } from 'react-redux';
import { initiateConfirm } from '@actions/confirm_actions';
import request from '~/app/assets/javascripts/utils/request';
import logErrorMessage from '~/app/assets/javascripts/utils/log_error_message';

const AddToWatchlistButton = ({ slug, prefix = 'Students' }) => {
  const addToWatchlist = () => {
    request(`/courses/${slug}/students/add_to_watchlist`, { method: 'POST' })
      .catch((error) => {
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

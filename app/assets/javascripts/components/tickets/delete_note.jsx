import React from 'react';
import { useDispatch } from 'react-redux';
import { deleteNote } from '../../actions/tickets_actions';

const DeleteNote = ({ messageId }) => {
  const dispatch = useDispatch();
  const onClick = (e) => {
    e.preventDefault();
    dispatch(deleteNote(messageId));
  };
  return (
    <button type="button" onClick={onClick} aria-label={I18n.t('survey.delete_note')}>
      <img src="/assets/images/delete-icon.png" alt="" />
    </button>
  );
};



export default (DeleteNote);

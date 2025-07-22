import React from 'react';
import { useDispatch } from 'react-redux';
import { deleteNote } from '../../actions/tickets_actions';

const DeleteNote = ({ messageId }) => {
  const dispatch = useDispatch();
  const onClick = (e) => {
    e.preventDefault();
    dispatch(deleteNote(messageId));
  };
  return <img src="/assets/images/delete-icon.png" alt="delete icon" onClick={onClick} />;
};



export default (DeleteNote);

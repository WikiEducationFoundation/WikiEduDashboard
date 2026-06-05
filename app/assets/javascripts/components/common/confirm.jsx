import React, { useEffect, useRef, useState } from 'react';
import { useDispatch, useSelector } from 'react-redux';

import Modal from './modal.jsx';
import TextInput from './text_input.jsx';
import { confirmAction, cancelAction } from '../../actions';

const Confirm = () => {
  const dispatch = useDispatch();

  const confirmationActive = useSelector(state => state.confirm.confirmationActive);
  const confirmMessage = useSelector(state => state.confirm.confirmMessage);
  const explanation = useSelector(state => state.confirm.explanation);
  const onConfirm = useSelector(state => state.confirm.onConfirm);
  const showInput = useSelector(state => state.confirm.showInput);
  const warningMessage = useSelector(state => state.confirm.warningMessage);

  const [userInput, setUserInput] = useState('');

  const confirmButtonRef = useRef(null);

  useEffect(() => {
    if (confirmationActive) {
      confirmButtonRef.current?.focus();
    }
  }, [confirmationActive]);

  const onConfirmClick = () => {
    onConfirm(userInput);
    dispatch(confirmAction());
  };

  const onCancel = () => {
    dispatch(cancelAction());
  };

  const onChange = (_valueKey, value) => {
    setUserInput(value);
  };

  if (!confirmationActive) { return <div />; }

  return (
    <Modal modalClass="confirm-modal-overlay" ariaLabelledBy="confirm-message">
      <div className="confirm-modal">
        {explanation && (
          <div className="confirm-explanation">
            {explanation}
            <br />
            <br />
          </div>
        )}
        {showInput ? (
          <>
            <div id="confirm-message">
              {confirmMessage}
            </div>
            <div>
              <TextInput
                value={userInput}
                value_key="userInput"
                onChange={onChange}
                editable
              />
            </div>
          </>
        ) : (
          <p id="confirm-message">{confirmMessage}</p>
        )}

        {warningMessage && (
          <div className="warning slim">
            <p dangerouslySetInnerHTML={{ __html: warningMessage }} />
          </div>
        )}
        {!showInput && <br />}
        <div className="pop_container pull-right">
          <button className="button ghost-button" onClick={onCancel}>{I18n.t('application.cancel')}</button>
          <button ref={confirmButtonRef} className="button dark" onClick={onConfirmClick}>{I18n.t('application.confirm')}</button>
        </div>
      </div>
    </Modal>
  );
};

export default (Confirm);

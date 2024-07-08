import React, { useState } from 'react';
import PropTypes from 'prop-types';
import Modal from '../../../components/common/modal.jsx';
import TransferStep1 from './transfer_step1.jsx';
import TransferStep2 from './transfer_step2.jsx';
import TransferStep3 from './transfer_step3.jsx';

const STEPS = {
  SOURCE_CATEGORY: 1,
  CHOOSE_MODULES: 2,
  DESTINATION_CATEGORY: 3,
};

const getInstruction = (step) => {
  switch (step) {
    case STEPS.SOURCE_CATEGORY:
      return I18n.t('training.source_category_msg');
    case STEPS.CHOOSE_MODULES:
      return I18n.t('training.choose_modules_msg');
    case STEPS.DESTINATION_CATEGORY:
      return I18n.t('training.destination_category_msg');
    default:
      return '';
  }
};

const TransferModules = ({ toggleModal }) => {
  const [submitting, setSubmitting] = useState(false);
  const [transferInfo, setTransferInfo] = useState({});
  const [step, setStep] = useState(STEPS.SOURCE_CATEGORY);

  const formClassName = submitting ? 'form-submitting' : '';

  return (
    <Modal>
      <div className="container">
        <div className={`wizard__panel active training_modal single_column ${formClassName}`}>
          <h3>{I18n.t('training.transfer_module')}</h3>
          <p>{getInstruction(step)}</p>
          <TransferStep1
            transferInfo={transferInfo}
            setTransferInfo={setTransferInfo}
            step={step}
            setStep={setStep}
            toggleModal={toggleModal}
          />
          <TransferStep2
            transferInfo={transferInfo}
            setTransferInfo={setTransferInfo}
            step={step}
            setStep={setStep}
          />
          <TransferStep3
            transferInfo={transferInfo}
            setTransferInfo={setTransferInfo}
            step={step}
            setStep={setStep}
            setSubmitting={setSubmitting}
          />
        </div>
      </div>
    </Modal>
  );
};

TransferModules.propTypes = {
  toggleModal: PropTypes.func.isRequired,
};

export default TransferModules;

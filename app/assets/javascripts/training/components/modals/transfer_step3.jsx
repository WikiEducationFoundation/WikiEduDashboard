import React from 'react';
import { useDispatch } from 'react-redux';
import { useParams } from 'react-router-dom';
import SelectableBox from '../../../components/common/selectable_box.jsx';
import { transferModules } from '../../../actions/training_modification_actions.js';

// Choose category to which user wants to transfer module
const TransferStep3 = ({ categories, transferInfo, setTransferInfo, step, setStep, setSubmitting }) => {
  const { library_id } = useParams();
  const remainingCategories = categories.filter(cat => cat.title !== transferInfo.sourceCategory);
  const dispatch = useDispatch();

  const handleCategorySelection = (selectedCategory) => {
    setTransferInfo(prev => ({ ...prev, destinationCategory: selectedCategory }));
  };

  const submitHandler = () => {
    setSubmitting(true);
    dispatch(transferModules(library_id, transferInfo, setSubmitting));
  };

  return (
    <div style={{ display: step === 3 ? 'block' : 'none' }}>
      <div style={{ paddingBottom: '20px' }} className="training_scrollable_container">
        {remainingCategories.map(category => (
          <SelectableBox
            key={category.title}
            onClick={() => handleCategorySelection(category.title)}
            heading={category.title}
            description={category.description}
            selected={transferInfo?.destinationCategory === category.title}
          />
        ))}
      </div>
      <button className="button light" onClick={() => setStep(2)}>{I18n.t('training.back')}</button>
      <button className="button dark right" onClick={submitHandler} disabled={!transferInfo.destinationCategory}>
        {I18n.t('training.transfer')}
      </button>
    </div>
  );
};

export default TransferStep3;

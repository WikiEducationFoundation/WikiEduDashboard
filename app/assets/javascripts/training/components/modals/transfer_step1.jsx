import React from 'react';
import SelectableBox from '../../../components/common/selectable_box.jsx';

// Choose category from which modules were transferred
const TransferStep1 = ({ categories, transferInfo, setTransferInfo, step, setStep, toggleModal }) => {
  const handleCategorySelection = (selectedCategory) => {
    setTransferInfo(prev => ({ ...prev, sourceCategory: selectedCategory }));
  };
  const nonEmptyCategories = categories.filter(cat => cat.modules.length > 0);

  return (
    <div style={{ display: step === 1 ? 'block' : 'none' }}>
      <div style={{ paddingBottom: '20px' }} className="training_scrollable_container">
        {nonEmptyCategories.map(category => (
          <SelectableBox
            key={category.title}
            onClick={() => handleCategorySelection(category.title)}
            heading={category.title}
            description={category.description}
            selected={transferInfo?.sourceCategory === category.title}
          />
        ))}
      </div>
      <button className="button light" onClick={toggleModal}>{I18n.t('training.cancel')}</button>
      <button className="button dark right" onClick={() => setStep(2)} disabled={!transferInfo?.sourceCategory}>
        {I18n.t('training.next_button')}
      </button>
    </div>
  );
};

export default TransferStep1;


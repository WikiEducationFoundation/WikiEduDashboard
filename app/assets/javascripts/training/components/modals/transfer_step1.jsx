import React, { useState, useEffect } from 'react';
import SelectableBox from '../../../components/common/selectable_box.jsx';
import { extractCategoriesFromHtml } from '../../../utils/training_utils.js';

// Choose category from which modules were transferred
const TransferStep1 = ({ transferInfo, setTransferInfo, step, setStep, toggleModal }) => {
  const [categories, setCategories] = useState([]);

  const handleCategorySelection = (selectedCategory) => {
    setTransferInfo(prev => ({ ...prev, sourceCategory: selectedCategory }));
  };

  useEffect(() => {
    const setCategoriesFromHtml = () => {
      const extractedCategories = extractCategoriesFromHtml();
      setCategories(extractedCategories);
      const event = new CustomEvent('categoriesReady', { detail: { categories: extractedCategories } });
      document.dispatchEvent(event);
    };

    if (document.readyState === 'complete' || document.readyState === 'interactive') {
      setCategoriesFromHtml();
    } else {
      document.addEventListener('DOMContentLoaded', setCategoriesFromHtml);
    }

    return () => {
      document.removeEventListener('DOMContentLoaded', setCategoriesFromHtml);
    };
  }, []);

  return (
    <div style={{ display: step === 1 ? 'block' : 'none' }}>
      <div style={{ paddingBottom: '20px' }}>
        {categories.map(category => (
          <SelectableBox
            key={category.name}
            onClick={() => handleCategorySelection(category.name)}
            heading={category.name}
            description={category.description}
            selected={transferInfo?.sourceCategory === category.name}
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


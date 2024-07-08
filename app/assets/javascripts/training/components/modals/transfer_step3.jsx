import React, { useState, useEffect } from 'react';
import { useDispatch } from 'react-redux';
import { useParams } from 'react-router-dom';
import SelectableBox from '../../../components/common/selectable_box.jsx';
import { transferModules } from '../../../actions/training_modification_actions.js';
import { extractCategoriesFromHtml } from '../../../utils/training_utils.js';

// Choose category to which user wants to transfer module
const TransferStep3 = ({ transferInfo, setTransferInfo, step, setStep, setSubmitting }) => {
  const { library_id } = useParams();
  const [categories, setCategories] = useState([]);
  const dispatch = useDispatch();

  const handleCategorySelection = (selectedCategory) => {
    setTransferInfo(prev => ({ ...prev, destinationCategory: selectedCategory }));
  };

  const submitHandler = () => {
    setSubmitting(true);
    dispatch(transferModules(library_id, transferInfo, setSubmitting));
  };

  useEffect(() => {
    const setCategoriesFromHtml = () => {
      const extractedCategories = extractCategoriesFromHtml();
      setCategories(extractedCategories.filter(category => category.name !== transferInfo?.sourceCategory));
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
  }, [transferInfo.sourceCategory]);

  return (
    <div style={{ display: step === 3 ? 'block' : 'none' }}>
      <div style={{ paddingBottom: '20px' }}>
        {categories.map(category => (
          <SelectableBox
            key={category.name}
            onClick={() => handleCategorySelection(category.name)}
            heading={category.name}
            description={category.description}
            selected={transferInfo?.destinationCategory === category.name}
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

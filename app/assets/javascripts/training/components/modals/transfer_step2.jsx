import React, { useEffect } from 'react';
import SelectableBox from '../../../components/common/selectable_box.jsx';

// Choose modules to transfer
const TransferStep2 = ({ categories, transferInfo, setTransferInfo, step, setStep }) => {
  const setModules = () => {
    const category = categories.find(cat => cat.title === transferInfo.sourceCategory);
    if (category) {
      return category.modules;
    }
    return [];
  };
  const allModules = setModules();

  const handleModuleSelection = (moduleName) => {
    setTransferInfo((prev) => {
      const modules = prev.modules.includes(moduleName)
        ? prev.modules.filter(module => module !== moduleName)
        : [...prev.modules, moduleName];
      return { ...prev, modules };
    });
  };

  useEffect(() => {
    setTransferInfo(prev => ({ ...prev, modules: [], destinationCategory: '' }));
  }, [transferInfo.sourceCategory]);

  return (
    <div style={{ display: step === 2 ? 'block' : 'none' }}>
      <div style={{ paddingBottom: '20px' }} className="training_scrollable_container">
        {allModules.map(module => (
          <SelectableBox
            key={module.name}
            onClick={() => handleModuleSelection(module.name)}
            heading={module.name}
            description={module.description}
            selected={transferInfo?.modules.includes(module.name)}
          />
        ))}
      </div>
      <button className="button light" onClick={() => setStep(1)}>{I18n.t('training.back')}</button>
      <button className="button dark right" onClick={() => setStep(3)} disabled={!transferInfo.modules?.length}>{I18n.t('training.next_button')}</button>
    </div>
  );
};

export default TransferStep2;

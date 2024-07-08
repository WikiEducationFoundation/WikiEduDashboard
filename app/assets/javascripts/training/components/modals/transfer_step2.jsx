import React, { useState, useEffect } from 'react';
import SelectableBox from '../../../components/common/selectable_box.jsx';

// Choose modules to transfer
const TransferStep2 = ({ transferInfo, setTransferInfo, step, setStep }) => {
  const [allModules, setAllModules] = useState([]);

  const handleModuleSelection = (moduleName) => {
    setTransferInfo((prev) => {
      const modules = prev.modules.includes(moduleName)
        ? prev.modules.filter(module => module !== moduleName)
        : [...prev.modules, moduleName];
      return { ...prev, modules };
    });
  };

  useEffect(() => {
    const extractModulesFromHtml = () => {
      const categoryElements = document.querySelectorAll('.training__categories > li');
      let modulesFromHtml = [];

      categoryElements.forEach((li) => {
        const categoryName = li.querySelector('.training__category__header h1')?.innerText.trim();
        if (categoryName === transferInfo.sourceCategory) {
          modulesFromHtml = Array.from(li.querySelectorAll('.training__categories__modules > li')).map((moduleLi) => {
            const name = moduleLi.querySelector('.action-card-title')?.innerText.trim();
            const description = moduleLi.querySelector('.action-card-text')?.innerText.trim();
            return { name, description };
          });
        }
      });

      return modulesFromHtml;
    };

    const setModulesFromHtml = () => {
      const extractedModules = extractModulesFromHtml();
      setAllModules(extractedModules);
    };

    setModulesFromHtml();
    setTransferInfo(prev => ({ ...prev, modules: [], destinationCategory: '' }));
  }, [transferInfo.sourceCategory]);

  return (
    <div style={{ display: step === 2 ? 'block' : 'none' }}>
      <div style={{ paddingBottom: '20px' }}>
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

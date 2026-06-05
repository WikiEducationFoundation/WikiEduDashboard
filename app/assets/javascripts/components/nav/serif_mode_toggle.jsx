import React, { useEffect, useState } from 'react';

const STORAGE_KEY = 'serifMode';

const readPreference = () => {
  try {
    return localStorage.getItem(STORAGE_KEY);
  } catch (e) {
    return null;
  }
};

const SerifModeToggle = () => {
  const [pref, setPref] = useState(readPreference);

  useEffect(() => {
    document.documentElement.classList.toggle('serif-mode', pref === 'true');
  }, [pref]);

  if (pref === null) return null;

  const select = (next) => {
    if (next === (pref === 'true')) return;
    const value = String(next);
    setPref(value);
    try {
      localStorage.setItem(STORAGE_KEY, value);
    } catch (e) { /* localStorage unavailable */ }
  };

  const isSerif = pref === 'true';

  return (
    <span className="font-toggle" role="group" aria-label={I18n.t('application.font_label')}>
      <button
        type="button"
        className={`font-toggle__btn font-toggle__btn--sans${isSerif ? '' : ' active'}`}
        aria-pressed={!isSerif}
        onClick={() => select(false)}
      >
        {I18n.t('application.font_sans')}
      </button>
      <button
        type="button"
        className={`font-toggle__btn font-toggle__btn--serif${isSerif ? ' active' : ''}`}
        aria-pressed={isSerif}
        onClick={() => select(true)}
      >
        {I18n.t('application.font_serif')}
      </button>
    </span>
  );
};

export default SerifModeToggle;

import React, { useState } from 'react';

function FastTrainingAlert() {
  const [open, setOpen] = useState(true);

  return (
    <>
      {open && (
        <div className="blur-backdrop-for-alert-box" onClick={() => setOpen(false)}>
          <div className="alert-box-container">
            <div className="alert-box">
              <h2 className="alert-title">{I18n.t('training.fast_alert_title')}</h2>
              <p className="alert-content">{I18n.t('training.fast_alert_content')}</p>
              <div className="alert-button-container">
                <button
                  className="alert-button"
                  onClick={() => setOpen(false)}
                >
                  {I18n.t('training.fast_alert_close')}
                </button>
              </div>
            </div>
          </div>
        </div>
      )}
    </>
  );
}

let count = 0;
let nooftimes = 0;
let enteringTime = new Date().getTime();
const MAX_NO_TIMES_ALERT_SHOWN = 1;
// min time spent for 3 clicks to trigger alert set to 10 seconds
const MIN_TIME_SPENT = 10000;
const MAX_CLICK_COUNT = 3;

/**
 * Handler for the fast training alert.
 * Fixes "line noise" where the alert could trigger multiple times or toggle off unexpectedly.
 */
const fastTrainingAlertHandler = (routeParams, setIsShown) => {
  if (routeParams.library_id === 'students') {
    if (count === 0) {
      enteringTime = new Date().getTime();
    }
    count += 1;

    if (count > MAX_CLICK_COUNT) {
      const clickingTime = new Date().getTime() - enteringTime;
      // Trigger alert if more than 3 clicks (4th click) occur within 10 seconds of entering
      // and ensure it only shows once (nooftimes < 1).
      if (clickingTime < MIN_TIME_SPENT && nooftimes < MAX_NO_TIMES_ALERT_SHOWN) {
        setIsShown(true);
        nooftimes += 1;
      }
      count = 0; // reset the click counter and timer for the next batch
    }
  }
};

export { FastTrainingAlert, fastTrainingAlertHandler };

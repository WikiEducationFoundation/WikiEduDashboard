import React, { useState } from 'react';

function FastTrainingAlert() {
  const [open, setOpen] = useState(true);

  return (
    <>
      {open && (
        <div className="blur-backdrop-for-alert-box" onClick={() => setOpen(false)}>
          <div className="alert-box-container">
            <div className="alert-box">
              <h2 className="alert-title">Please take your time!</h2>
              <p className="alert-content">It is very important that you learn the training content thoroughly.</p>
              <div className="alert-button-container">
                <button className="alert-button" onClick={() => setOpen(false)}>CLOSE</button>
              </div>
            </div>
          </div>
        </div>
      )};
    </>
  );
}

let count = 0;
let nooftimes = 0;
const enteringTime = new Date().getTime();
const max_no_times_alert_shown = 1;
const min_time_spent = 10000;
const max_click_count = 3;

const fastTrainingAlertHandler = (routeParams, setIsShown) => {
  if (routeParams.library_id === 'students') {
    count += 1;
    const clickingTime = new Date().getTime() - enteringTime;
    if (count > max_click_count && clickingTime < min_time_spent && nooftimes <= max_no_times_alert_shown) {
      setIsShown(current => !current);
      nooftimes += 1;
      count = 0;
    }
  }
};

export { FastTrainingAlert, fastTrainingAlertHandler };

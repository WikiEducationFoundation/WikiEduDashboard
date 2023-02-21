import React, { useState } from 'react';

export default function FastTrainingAlert() {
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

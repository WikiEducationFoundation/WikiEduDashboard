import React, { useState } from 'react';
import useOutsideClick from '../../hooks/useOutsideClick';

const PeerReviewChecklist = () => {
  const [isVisible, setIsVisible] = useState(false);
  const show = () => {
    setIsVisible(true);
  };

  const hide = () => {
    setIsVisible(false);
  };

  const ref = useOutsideClick(hide);

  let button;
  if (isVisible) {
    button = <button onClick={hide} className="button dark small">Okay</button>;
  } else {
    button = <a onClick={show} className="button dark small">Peer review checklist</a>;
  }

  let modal;
  if (!isVisible) {
    modal = <div className="empty" />;
  } else {
    modal = (
      <div ref={ref} className="article-viewer my-assignment-checklist">
        <h2>Peer review checklist</h2>
        <p>
          Your goal with a peer review is to identify specific ways the article could be improved, and note any major problems that ought to be fixed. Consider these questions:
        </p>
        <dl>
          <dd><input type="checkbox" /> Is everything in the article relevant to the article topic? Is there anything that distracted you?</dd>
          <dd><input type="checkbox" /> Is the article neutral? Are there any claims, or frames, that appear heavily biased toward a particular position?</dd>
          <dd><input type="checkbox" /> Are there viewpoints that are overrepresented, or underrepresented?</dd>
          <dd><input type="checkbox" /> Check the citations. Do the links work? Does the source support the claims in the article?</dd>
          <dd><input type="checkbox" /> Is each fact supported by an appropriate, reliable reference? Where does the information come from? Are these neutral sources? If biased, is that bias noted?</dd>
          <dd><input type="checkbox" /> Is any information out of date? Is anything missing that should be added?</dd>
        </dl>
        {button}
      </div>
    );
  }

  return (
    <div>
      {button}
      {modal}
    </div>
  );
};

export default PeerReviewChecklist;

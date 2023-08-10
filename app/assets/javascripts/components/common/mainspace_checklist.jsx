import React, { useState } from 'react';
import useOutsideClick from '../../hooks/useOutsideClick';

const MainspaceChecklist = () => {
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
    button = <a onClick={show} className="button dark small">Quality checklist</a>;
  }

  let modal;
  if (!isVisible) {
    modal = <div className="empty" />;
  } else {
    modal = (
      <div ref={ref} className="article-viewer my-assignment-checklist">
        <h2>Quality checklist</h2>
        <p>
          Before your article can become a live Wikipedia
          article, make sure meets all these criteria.
        </p>
        <dl>
          <dd><input type="checkbox" /> It starts with a clear definition of the topic, with the title in the first sentence in <strong>bold</strong>.</dd>
          <dd><input type="checkbox" /> It has a lead section — which comes before any section headers — that provides an overview of the topic.</dd>
          <dd><input type="checkbox" /> If it has additional sections after the lead, they have content, not just a placeholder.</dd>
          <dd><input type="checkbox" /> The content has inline citations, not just a bibliography.</dd>
          <dd><input type="checkbox" /> It has a &quot;References&quot; section after the body of the article.</dd>
          <dd><input type="checkbox" /> All comments, notes, and outlines have been removed from the draft.</dd>
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

export default MainspaceChecklist;

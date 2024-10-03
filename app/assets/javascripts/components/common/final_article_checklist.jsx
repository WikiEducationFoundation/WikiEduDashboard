import React, { useState } from 'react';
import useOutsideClick from '../../hooks/useOutsideClick';

const FinalArticleChecklist = () => {
  const checklistItems = [
    { key: '1', label: "The title is short and simple. It doesn't look like an essay, or ask a question." },
    { key: '2', label: 'The first sentence is direct and useful; it clearly defines the subject, with the topic of the article in bold.' },
    { key: '3', label: 'The lead section is a clear summary, not an introduction or argument. A reader could stop at the end of the lead and have a good overview of the most important aspects of the topic.' },
    { key: '4', label: "It doesn't contain excessive quotations, or copy any sources (even if you've given them credit)." },
    { key: '5', label: "The writing is clear to a non-expert; you've explained acronyms and jargon in simple English the first time you use them." },
    { key: '6', label: 'It lets readers decide for themselves, without any persuasive language that aims to sway a reader to a conclusion.' },
    { key: '7', label: "You've proof-read it all the way through. Grammar and spelling are correct, sentences are complete sentences, and there is no first-person (“I/we”) or second-person (“you”) writing." },
    { key: '8', label: 'The formatting is consistent with the rest of Wikipedia, without too many headings. Bulleted lists are used sparingly or not at all.' },
    { key: '9', label: "Every claim is cited to a reliable source — like a textbook or academic journal — and it doesn't cite any blog posts." },
    { key: '10', label: 'The text includes links to other Wikipedia articles the first time each relevant topic is mentioned.' },
    { key: '11', label: 'At least one related Wikipedia article links back to this one.' },
    { key: '12', label: "You've thanked people who helped you. Check your User Talk page, and the Talk page of your article. If anyone offered help or feedback, say thanks!" },
  ];

  const [isVisible, setIsVisible] = useState(false);
  const [checkboxStates, setCheckboxStates] = useState(
    Object.fromEntries(
      checklistItems.map(item => [item.key, false])
    )
  );

  const show = () => setIsVisible(true);
  const hide = () => setIsVisible(false);

  const toggleCheckbox = (checkboxName) => {
    setCheckboxStates(prevState => ({
      ...prevState,
      [checkboxName]: !prevState[checkboxName],
    }));
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
        <h2>Final review checklist</h2>
        <p>
          As you polish up your completed article, review each of these items and fix any problems you find.
        </p>
        <dl>
          {checklistItems.map(item => (
            <dd key={item.key}>
              <input
                type="checkbox"
                checked={checkboxStates[item.key]}
                onChange={() => toggleCheckbox(item.key)}
              />
              {item.label}
            </dd>
          ))}
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

export default FinalArticleChecklist;

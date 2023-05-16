import React from 'react';

export const ScopingMethod = ({
  name,
  description,
  index,
  nextPage,
  prevPage,
  canGoNext,
  wizardController,
}) => {
  return (
    <>
      <h1>{name}</h1>
      <p>{description}</p>
      {/* if we there any remaining scoping methods, show the next button */}
      {/* otherwise, display the create course button(part of wizard controller) */}
      {canGoNext ? (
        <div
          style={{
            display: 'flex',
            justifyContent: 'space-between',
          }}
        >
          <button
            onClick={prevPage.bind(null, index)}
            className="dark button button__submit"
          >
            Prev
          </button>
          <button
            onClick={nextPage.bind(null, index)}
            className="dark button button__submit"
          >
            Next
          </button>
        </div>
      ) : (
        wizardController({ hidden: false, backFunction: prevPage.bind(null, index) })
      )}
    </>
  );
};

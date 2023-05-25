import React from 'react';

export const ScopingMethod = ({
  name,
  description,
  index,
  nextPage,
  prevPage,
  canGoNext,
  wizardController,
  children
}) => {
  return (
    <>
      <h3 style={{
        fontWeight: 'lighter',
      }}
      >{name}
      </h3>
      {description && description.split('\n').map((paragraph, i) => paragraph && <p key={i}>{paragraph}</p>)}
      <div style={{
        margin: '1.5em 0',
      }}
      >{children}
      </div>
      {/* if we there any remaining scoping methods, show the next button */}
      {/* otherwise, display the create course button(part of wizard controller) */}
      {canGoNext ? (
        <div
          style={{
            display: 'flex',
            justifyContent: 'space-between',
            borderTop: '1px solid #ced1dd',
            paddingTop: '20px'
          }}
        >
          <button
            onClick={prevPage.bind(null, index)}
            className="dark button button__submit"
          >
            Back
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

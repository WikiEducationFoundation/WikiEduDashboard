import React from 'react';
import { useDispatch, useSelector } from 'react-redux';
import { PETSCAN, UPDATE_PETSCAN_ON_HOME_PAGE } from '../../constants/scoping_methods';

export const ScopingMethod = ({
  name,
  description,
  index,
  nextPage,
  prevPage,
  canGoNext,
  wizardController,
  children,
  scopingMethod
}) => {
  const isOnPetScanHomePage = useSelector(state => state.scopingMethods.petscan.on_home_page);
  const dispatch = useDispatch();
  let ignorePageIndex = false;
  if (scopingMethod === PETSCAN && !isOnPetScanHomePage) {
    ignorePageIndex = true;
  }
  const dispatchGoToPetScanHomePage = (value) => {
    dispatch({
      type: UPDATE_PETSCAN_ON_HOME_PAGE,
      on_home_page: value,
    });
  };

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
            onClick={() => {
              if (ignorePageIndex) {
                dispatch({
                  type: UPDATE_PETSCAN_ON_HOME_PAGE,
                  on_home_page: true,
                });
              } else {
                prevPage(index);
              }
            }}
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
        wizardController({ hidden: false, backFunction: ignorePageIndex ? dispatchGoToPetScanHomePage.bind(null, true) : prevPage.bind(null, index) })
      )}
    </>
  );
};

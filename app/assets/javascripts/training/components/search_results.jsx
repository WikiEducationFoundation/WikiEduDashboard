import React from 'react';

const SearchResults = ({ slides, message }) => {
  if (slides && slides.length > 0) {
    return (
      <ul className="training-libraries no-bullets no-margin action-card-text">
        {slides.map((slide, index) => (
          <li key={index}>
            <a href={`https://dashboard.wikiedu.org/training/${slide.path}`} target="_blank">
              <span dangerouslySetInnerHTML={{ __html: slide.title }} /> ({slide.module_name})
            </a>
            <br />
            <div dangerouslySetInnerHTML={{ __html: slide.excerpt }} />
          </li>
        ))}
      </ul>
    );
  }
  return message;
};

export default SearchResults;

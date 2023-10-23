import React from 'react';

const SearchResults = ({ slides, message }) => {
  if (slides.length === 0) {
    return <p>{message}</p>;
  }

  return (
    <div>
      <ul className="training-libraries no-bullets no-margin action-card-text">
        {slides.map((slide, index) => (
          <li key={index}>
            <a href={`https://dashboard.wikiedu.org/${slide.path}`} target="_blank">
              {slide.title}
            </a>
            <br />
            Module: {slide.module_name}
            <br />
            <div dangerouslySetInnerHTML={{ __html: slide.excerpt }} />
          </li>
        ))}
      </ul>
    </div>
  );
};

export default SearchResults;

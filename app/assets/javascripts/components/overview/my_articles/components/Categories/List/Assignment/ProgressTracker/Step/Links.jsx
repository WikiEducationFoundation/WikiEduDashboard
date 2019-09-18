import React from 'react';
import { HashLink as Link } from 'react-router-hash-link';

export default ({ courseSlug, trainings }) => {
  const links = trainings.map((training, index) => {
    return training.external
      ? <a key={index} href={training.path} target="_blank">{training.title}</a>
      : (
        <Link
          key={index}
          to={`/courses/${courseSlug}/${training.path}`}
          scroll={el => el.scrollIntoView({ block: 'center' })}
        >
          {training.title}
        </Link>
      );
  });

  return (
    <aside className="step-links">
      {links}
    </aside>
  );
};

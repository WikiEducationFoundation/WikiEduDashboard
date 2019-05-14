import React from 'react';
import Block from '../timeline/block';

const handouts = [
  { name: 'Editing Wikipedia', link: 'https://wikiedu.org/editingwikipedia' },
  { name: 'Evaluating Wikipedia', link: 'https://wikiedu.org/evaluatingwikipedia' },
  { name: 'Illustrating Wikipedia', link: 'https://wikiedu.org/illustratingwikipedia' }
];

const Handouts = ({ blocks, trainingLibrarySlug }) => {
  let topicGuides;
  const topicGuidesBlock = blocks.find(block => block.title.match(/writing articles in your topic area/));
  if (topicGuidesBlock) {
    topicGuides = (
      <>
        <Block block={topicGuidesBlock} trainingLibrarySlug={trainingLibrarySlug} />
        <a href="https://wikiedu.org/for-instructors/#subject-specific" className="button pull-right" target="_blank">Additional subject-specific guides</a>
      </>
    );
  }

  const links = handouts.map((handout) => {
    return (
      <a key={handout.link} className="handout-link ml1" href={handout.link}>{handout.name}</a>
    );
  });

  return (
    <div id="handouts" className="list-unstyled container block__training-modules">
      <h4>Handouts (PDF)</h4>
      <li className="block">
        <h3 className="block-title">General guides</h3>
        {links}
      </li>
      {topicGuides}
    </div>
  );
};

export default Handouts;

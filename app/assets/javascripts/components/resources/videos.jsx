import React from 'react';

const videos = [
  { title: 'Adding content to an existing Wikipedia article', link: 'https://dashboard.wikiedu.org/training/students/videos/adding-content-demo-video' },
  { title: 'Creating a new Wikipedia article', link: 'https://dashboard.wikiedu.org/training/students/videos/creating-a-new-article-demo-video' }
];

const VideoLink = ({ link, title }) => (
  <tr className="training-module">
    <td className="block__training-modules-table__module-name">{ title }</td>
    <td className="block__training-modules-table__module-link">
      <a href={link} target="_blank">
        Watch
        <i className="icon icon-rt_arrow" />
      </a>
    </td>
  </tr>
);

const Videos = () => {
  return (
    <div className="list-unstyled container mt2 mb2">
      <h4>Videos</h4>
      <table className="table table--small">
        <tbody>
          { videos.map((vid, i) => <VideoLink key={`video-${i}`} {...vid} />) }
        </tbody>
      </table>
    </div>
  );
};

export default Videos;

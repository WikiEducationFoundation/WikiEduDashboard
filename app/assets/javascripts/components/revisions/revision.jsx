import React from 'react';
import DiffViewer from './diff_viewer.jsx';

const Revision = React.createClass({
  displayName: 'Revision',

  propTypes: {
    revision: React.PropTypes.object
  },

  render() {
    const ratingClass = `rating ${this.props.revision.rating}`;
    const ratingMobileClass = `${ratingClass} tablet-only`;

    return (
      <tr className="revision">
        <td className="tooltip-trigger desktop-only-tc">
          <p className="rating_num hidden">{this.props.revision.rating_num}</p>
          <div className={ratingClass}><p>{this.props.revision.pretty_rating || '-'}</p></div>
          <div className="tooltip dark">
            <p>{I18n.t(`articles.rating_docs.${this.props.revision.rating || '?'}`)}</p>
          </div>
        </td>
        <td>
          <div className={ratingMobileClass}><p>{this.props.revision.pretty_rating || '-'}</p></div>
          <a onClick={this.stop} href={this.props.revision.article_url} target="_blank" className="inline"><p className="title">{this.props.revision.title}</p></a>
        </td>
        <td className="desktop-only-tc">{this.props.revision.revisor}</td>
        <td className="desktop-only-tc">{this.props.revision.characters}</td>
        <td className="desktop-only-tc date"><a href={this.props.revision.url}>{moment(this.props.revision.date).format('YYYY-MM-DD   h:mm A')}</a></td>
        <td>
          <DiffViewer revision={this.props.revision}
                      charCount={this.props.revision.characters}
          />
        </td>
      </tr>
    );
  }
}
);

export default Revision;

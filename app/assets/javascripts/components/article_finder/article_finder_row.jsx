import React from 'react';
import createReactClass from 'create-react-class';

const ArticleFinderRow = createReactClass({
  render() {
    return (
      <tr>
        <td>
          {this.props.article.title}
        </td>
        <td>
          Views per day
        </td>
        <td>
          Completeness Estimate
        </td>
      </tr>);
  }
});

export default ArticleFinderRow;

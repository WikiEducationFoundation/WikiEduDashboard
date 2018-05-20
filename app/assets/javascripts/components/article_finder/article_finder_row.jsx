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
          {this.props.article.pageviews}
        </td>
        <td>
          Completeness Estimate
        </td>
        <td>
          {this.props.article.grade}
        </td>
      </tr>);
  }
});

export default ArticleFinderRow;

import React from 'react';
import Expandable from '../high_order/expandable.jsx';
import ArticleDetailsStore from '../../stores/article_details_store.js';

const getArticleDetails = () => ArticleDetailsStore.getModels();

const ArticleDrawer = React.createClass({
  displayName: 'ArticleDrawer',

  propTypes: {
    article: React.PropTypes.object,
    is_open: React.PropTypes.bool
  },

  mixins: [ArticleDetailsStore.mixin],

  getInitialState() {
    return {
      articleDetails: getArticleDetails()
    };
  },

  getKey() {
    return `drawer_${this.props.article.id}`;
  },

  storeDidChange() {
    return this.setState({
      articleDetails: getArticleDetails()
    });
  },

  render() {
    if (!this.props.is_open) { return <tr></tr>; }

    let className = 'drawer';
    className += !this.props.is_open ? ' closed' : '';

    return (
      <tr className={className}>
        <td colSpan="7">
          <span />
          <table className="table">
            <thead>
              <tr>
                <th>
                  header
                </th>
              </tr>
            </thead>
            <tbody>
              <tr>
                <td>
                  drawer body
                </td>
              </tr>
            </tbody>
          </table>
        </td>
      </tr>
    );
  }
});

export default Expandable(ArticleDrawer);

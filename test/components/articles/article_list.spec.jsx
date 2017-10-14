import '../../testHelper';

import React from 'react';
import ReactTestUtils from 'react-dom/test-utils';

import ArticleList from '../../../app/assets/javascripts/components/articles/article_list.jsx';

describe('ArticleList', () => {
  it('renders articles', () => {
    const articles = [{
      id: 1,
      rating: 'start',
      rating_num: 6,
      pretty_rating: 's',
      url: 'articleUrl',
      character_sum: 10,
      view_count: 5,
      language: 'en',
      title: 'articleTitle',
      new_article: false
    }, {
      id: 2,
      rating: 'start',
      rating_num: 6,
      pretty_rating: 's',
      url: 'articleUrl2',
      character_sum: 10,
      view_count: 5,
      language: 'en',
      title: 'articleTitle2',
      new_article: true
    }];

    ArticleList.__Rewire__('ArticleStore', {
      getModels() {
        return articles;
      },
      getSorting() {
        return {
          sortKey: 'title',
          sortAsc: true
        };
      }
    });

    const TestArticle = ReactTestUtils.renderIntoDocument(
      <div>
        <ArticleList articles={articles} course={{ home_wiki: {} }} store={reduxStore} />
      </div>
    );

    expect(TestArticle.textContent).to.contain('articleTitle');
    expect(TestArticle.textContent).to.contain('articleTitle2');
  });
});

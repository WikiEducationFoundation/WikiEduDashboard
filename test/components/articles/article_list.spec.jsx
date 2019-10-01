import React from 'react';
import ReactTestUtils from 'react-dom/test-utils';
import { Provider } from 'react-redux';

import '../../testHelper';

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
      references_count: 5,
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
      references_count: 2,
      view_count: 5,
      language: 'en',
      title: 'articleTitle2',
      new_article: true
    }];

    const TestArticle = ReactTestUtils.renderIntoDocument(
      <div>
        <Provider store={reduxStore}>
          <ArticleList
            wikis={[]}
            articles={articles}
            course={{ home_wiki: {} }}
            wikidataLabels={{}}
          />
        </Provider>
      </div>
    );

    expect(TestArticle.textContent).toContain('articleTitle');
    expect(TestArticle.textContent).toContain('articleTitle2');
  });
});


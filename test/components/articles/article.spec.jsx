import React from 'react';
import ReactTestUtils from 'react-dom/test-utils';
import { Provider } from 'react-redux';

import '../../testHelper';
import Article from '../../../app/assets/javascripts/components/articles/article.jsx';

const course = {
  home_wiki: { language: 'en', project: 'wikipedia' }
};

describe('Article', () => {
  it('renders', () => {
    const article = {
      id: 99,
      rating: 'start',
      rating_num: 6,
      pretty_rating: 's',
      url: 'articleUrl',
      character_sum: 10,
      references_count: 5,
      view_count: 5,
      language: 'en',
      project: 'wikipedia',
      title: 'articleTitle',
      new_article: false
    };

    const TestArticle = ReactTestUtils.renderIntoDocument(
      <table>
        <tbody>
          <Provider store={reduxStore}>
            <Article
              article={article}
              course={course}
              isOpen={false}
              toggleDrawer={() => {}}
              fetchArticleDetails={() => {}}
              articleDetails={null}
            />
          </Provider>
        </tbody>
      </table>
    );

    expect(TestArticle.textContent).not.toContain('(new)');
    expect(TestArticle.textContent).toContain('articleTitle');
  });

  it('adds "(new)" to new articles', () => {
    const article = {
      id: 99,
      rating: 'start',
      rating_num: 6,
      pretty_rating: 's',
      url: 'articleUrl',
      character_sum: 10,
      references_count: 5,
      view_count: 5,
      language: 'en',
      project: 'wikipedia',
      title: 'articleTitle',
      new_article: true
    };

    const TestArticle = ReactTestUtils.renderIntoDocument(
      <table>
        <tbody>
          <Provider store={reduxStore}>
            <Article
              article={article}
              course={course}
              isOpen={false}
              toggleDrawer={() => {}}
              fetchArticleDetails={() => {}}
              articleDetails={null}
            />
          </Provider>
        </tbody>
      </table>
    );

    expect(TestArticle.textContent).toContain('(new)');
  });
});

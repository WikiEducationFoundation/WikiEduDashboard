import '../../testHelper';

import React from 'react';
import ReactTestUtils from 'react-addons-test-utils';

import Article from '../../../app/assets/javascripts/components/articles/article.jsx';

describe('Article', () => {
  it('renders', () => {
    const article = {
      rating: 'start',
      rating_num: 6,
      pretty_rating: 's',
      url: 'articleUrl',
      character_sum: 10,
      view_count: 5,
      language: 'en',
      title: 'articleTitle',
      new_article: false
    };

    const TestArticle = ReactTestUtils.renderIntoDocument(
      <table>
        <tbody>
          <Article article={article} />
        </tbody>
      </table>
    );

    expect(TestArticle.textContent).to.not.contain('(new)');
    expect(TestArticle.textContent).to.contain('articleTitle');
  });

  it('adds "(new)" to new articles', () => {
    const article = {
      rating: 'start',
      rating_num: 6,
      pretty_rating: 's',
      url: 'articleUrl',
      character_sum: 10,
      view_count: 5,
      language: 'en',
      title: 'articleTitle',
      new_article: true
    };

    const TestArticle = ReactTestUtils.renderIntoDocument(
      <table>
        <tbody>
          <Article article={article} />
        </tbody>
      </table>
    );

    expect(TestArticle.textContent).to.contain('(new)');
  });
});

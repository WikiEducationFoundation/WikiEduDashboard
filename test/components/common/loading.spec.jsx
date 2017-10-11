import '../../testHelper';
import Loading from '../../../app/assets/javascripts/components/common/loading.jsx';
import React from 'react';
import ReactTestUtils from 'react-dom/test-utils';

describe('Loading', () => {
  it('renders a div with an h1 and a div', () => {
    const renderer = ReactTestUtils.createRenderer();
    renderer.render(<Loading />);
    const output = renderer.getRenderOutput();
    expect(output.type).to.eq('div');
    expect(output.props.children[0].type).to.eq('h1');
    expect(output.props.children[1].type).to.eq('div');
  });
});

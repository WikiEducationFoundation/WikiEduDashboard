import React from 'react';
import ShallowTestUtils from 'react-test-renderer/shallow';

// TextInput uses Conditional as a wrapper, so we'll test the intended behavior
// through it, instead of trying to test Conditional directly or with mocks.
import TextInput from '../../../app/assets/javascripts/components/common/text_input.jsx';
import '../../testHelper';

describe('Conditional', () => {
  it('renders a connected instance of the wrapped component when show is true', () => {
    const renderer = ShallowTestUtils.createRenderer();
    renderer.render(
      <TextInput
        show={true}
        value={'foo'}
      />
    );
    const textInput = renderer.getRenderOutput();
    expect(textInput.type.displayName).to.eq('Connect(InputTextInput)');
    expect(textInput.props.value).to.eq('foo');
  });

  it('renders nothing when show is false', () => {
    const renderer = ShallowTestUtils.createRenderer();
    renderer.render(
      <TextInput
        show={false}
        value={'foo'}
      />
    );
    const textInput = renderer.getRenderOutput();
    expect(textInput).to.be.null;
  });
});

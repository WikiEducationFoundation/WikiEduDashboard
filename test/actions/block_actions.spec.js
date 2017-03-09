import '../testHelper';
import BlockActions from '../../app/assets/javascripts/actions/block_actions.js';
import BlockStore from '../../app/assets/javascripts/stores/block_store.js';

describe('BlockActions', () => {
  let stubbedAjax;

  beforeEach(() => {
    stubbedAjax = sinon.stub($, "ajax");
  });
  afterEach(() => {
    $.ajax.restore();
  });

  it('.addBlock sets a new block', (done) => {
    expect(BlockStore.getBlocks().length).to.eq(0);
    BlockActions.addBlock(1).then(() => {
      expect(BlockStore.getBlocks().length).to.eq(1);
      done();
    });
  });

  it('.updateBlock changes a block', (done) => {
    const blockId = BlockStore.getBlocks()[0].id;
    const block = { id: blockId, foo: 'bar' };
    expect(BlockStore.getBlocks()[0].foo).to.eq(undefined);
    BlockActions.updateBlock(block).then(() => {
      expect(BlockStore.getBlocks()[0].foo).to.eq('bar');
      done();
    });
  });

  it('.deleteBlock removes the specified block by ID', (done) => {
    expect(BlockStore.getBlocks().length).to.eq(1);
    const blockId = BlockStore.getBlocks()[0].id;
    stubbedAjax.onCall(0).yieldsTo("success", { block_id: blockId });
    BlockActions.deleteBlock(blockId).then(() => {
      expect(BlockStore.getBlocks().length).to.eq(0);
      done();
    });
  });
});

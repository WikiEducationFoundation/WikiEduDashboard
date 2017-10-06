import '../testHelper';
import BlockActions from '../../app/assets/javascripts/actions/block_actions.js';
import BlockStore from '../../app/assets/javascripts/stores/block_store.js';

describe('BlockActions', () => {
  let stubbedAjax;

  beforeAll(() => {
    stubbedAjax = sinon.stub($, "ajax");
  });
  afterAll(() => {
    $.ajax.restore();
    BlockStore.restore();
  });

  it('.addBlock sets a new block in the store', (done) => {
    expect(BlockStore.getBlocks().length).to.eq(0);
    BlockActions.addBlock(1).then(() => {
      expect(BlockStore.getBlocks().length).to.eq(1);
      done();
    });
  });

  it('.setEditable adds a blockId to the set of editable ones', (done) => {
    BlockStore.clearEditableBlockIds();
    expect(BlockStore.getEditableBlockIds().length).to.eq(0);
    const blockId = BlockStore.getBlocks()[0].id;
    BlockActions.setEditable(blockId).then(() => {
      expect(BlockStore.getEditableBlockIds().length).to.eq(1);
      expect(BlockStore.getEditableBlockIds()[0]).to.eq(blockId);
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

  it('.insertBlock adds a block to a specified week', (done) => {
    const weekId = BlockStore.getBlocks()[0].week_id;
    const newBlock = { foo: 'bar' };
    BlockActions.insertBlock(newBlock, { id: weekId }, 0).then(() => {
      expect(BlockStore.getBlocks()[0].week_id).to.eq(weekId);
      done();
    });
  });

  it('.deleteBlock removes the specified block by ID', (done) => {
    expect(BlockStore.getBlocks().length).to.eq(2);
    const blockId = BlockStore.getBlocks()[0].id;
    stubbedAjax.onCall(0).yieldsTo("success", { block_id: blockId });
    BlockActions.deleteBlock(blockId).then(() => {
      expect(BlockStore.getBlocks().length).to.eq(1);
      done();
    });
  });
});

import McFly from 'mcfly';
const Flux = new McFly();

const UIActions = Flux.createActions({
  open(key) {
    return {
      actionType: 'OPEN_KEY',
      data: {
        key
      }
    };
  },

  sort(kind, key) {
    return {
      actionType: `SORT_${kind.toUpperCase()}`,
      data: {
        key
      }
    };
  }
});

export default UIActions;

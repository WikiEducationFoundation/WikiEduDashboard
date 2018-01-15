import McFly from 'mcfly';
const Flux = new McFly();

const UIActions = Flux.createActions({
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

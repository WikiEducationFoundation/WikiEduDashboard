import McFly from 'mcfly';
const Flux = new McFly();

const ApiFailAction = Flux.createActions({
  fail(response) {
    return ({ actionType: 'API_FAIL', data: response });
  }
});

export default ApiFailAction;

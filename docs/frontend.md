[Back to README](../README.md)

## Front end Technology

The dashboard front end is primary built using React.js and Flux written in Coffeescript. What follows is an overview of how data moves through the app and some more general resources for understanding the stack.

### Resources
- [Thinking in React](https://facebook.github.io/react/docs/thinking-in-react.html)
- [Flux: Actions and the Dispatcher](https://facebook.github.io/react/blog/2014/07/30/flux-actions-and-the-dispatcher.html) - Note that the dispatcher is abstracted away in [McFly](https://github.com/kenwheeler/mcfly), the Flux implementation used on the Dashboard.

### Actions
Actions are exactly what they sound like: any impactful change front end user action should trigger a Flux action that can be received and acted upon by a store. Think of a Flux action as being similar to an emitted event.

##### ServerActions
ServerActions define a set of actions that interact with the Rails application via AJAX requests. Notably, several ServerActions are triggered by default when a course page is first loaded. These Actions trigger AJAX requests through the API helper and use a promise to emit an event for subscribed Stores when the AJAX request returns.

### Stores
Stores listen for Actions and are responsible for parsing, storing, and providing application data to all components. They can subscribe to any action and they can also emit a change event that is received by all subscribed components.

##### StockStore
StockStore is store factory that returns a Store implementing a set of features used by several different models in the Dashboard application. These include:

- Object CRUD
- Object filtering by key
- Object sorting by key
- Data persistence (user actions can be cancelled and changes reverted)
- Load state tracking (whether or not the store has received data from the server)

### Components
Components are the view layer of the JS application. They contain HTML markup and methods that trigger Actions based on user input.

##### High-order components

##### Common components

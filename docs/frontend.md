[Back to README](../README.md)

## Front end Technology

The dashboard front end is primary built using React.js and Flux written in Coffeescript. What follows is an overview of how data moves through the app and some more general resources for understanding the stack.

### Resources
- [Thinking in React](https://facebook.github.io/react/docs/thinking-in-react.html)
- [Flux: Actions and the Dispatcher](https://facebook.github.io/react/blog/2014/07/30/flux-actions-and-the-dispatcher.html) - Note that the dispatcher is abstracted away in [McFly](https://github.com/kenwheeler/mcfly), the Flux implementation used on the Dashboard.
- [React DnD](http://gaearon.github.io/react-dnd/) - The library used for drag-and-drop interactions on the timeline

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
[High-order components](/app/assets/javascripts/components/high_order) are essentially wrappers for passed components. [This post](https://medium.com/@dan_abramov/mixins-are-dead-long-live-higher-order-components-94a0d2f9e750) describes the idea very well. They are not polymorphic classes, they are a replacement for mixins. That is, they provide reusable methods or rendering patterns to the components that they wrap without violating idiomatic React (as mixins do).

The [Conditional component](/app/assets/javascripts/components/high_order/conditional.cjsx) is a simple example: it contains all of the logic for conditionally rendering a component based on a boolean prop. This means we can make any component render based on a boolean without repeating that logic. For example, adding this functionality to the Select component is as simple as changing 

	module.exports = Select
to

	module.exports = Conditional(Select)
	
and passing a `show` parameter to any Select used in our application.

##### Common components
Common components are utilities used throughout the application. These include inputs and modals, among others. They are not special components, they just don't belong to a specific part of the application.

### Utils
Utils include several different helpers for our application and two of them are worth an explanation.

#### Router
The [router.cjsx](/app/assets/javascripts/utils/router.cjsx) file contains an implementation of [React Router](https://github.com/rackt/react-router). Here we define handlers for different URL paths and structure a hierarchy that allows components to optionally wrap other components based on the URL. As of this writing the React Router library is undergoing some big restructuring for a 1.0 push but documentation for the current version [can be found here](http://rackt.github.io/react-router/).

#### API
The [api.coffee](/app/assets/javascripts/utils/api.coffee) file contains all AJAX requests for the application. Many methods are named according to their  purpose excepting the `fetch` and `modify` methods. These are written to be widely reused by `ServerActions` and require some extra hand-holding to ensure that the proper endpoint is reached.
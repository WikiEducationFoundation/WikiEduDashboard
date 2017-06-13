[Back to README](../README.md)

## Front end Technology

The dashboard front end is primary built using React.js, written in Javascript and JSX. What follows is an overview of how data moves through the app and some more general resources for understanding the stack. It was originally done with Flux (McFly), but as of May 2017, it is being gradually migrated to Redux.

### Resources
- [Thinking in React](https://facebook.github.io/react/docs/thinking-in-react.html)
- [Redux docs](http://redux.js.org/)
- [Getting Started with Redux](https://egghead.io/courses/getting-started-with-redux)
- [React DnD](http://gaearon.github.io/react-dnd/) - The library used for drag-and-drop interactions on the timeline

### Actions
Actions are exactly what they sound like: any impactful front end user action should trigger a Flux or Redux action that can be received and acted upon by a store. Think of a Flux action as being similar to an emitted event.

New features should rely on actions in the form of plain objects that are dispatched to the Redux store and handled via reducers, rather than the McFly/Flux actions that connect to one of many McFly stores. Redux actions may use Thunk middleware to handle async events like API requests.

### McFly Stores
These stores listen for Actions and are responsible for parsing, storing, and providing application data to all components. They can subscribe to any McFly action and they can also emit a change event that is received by all subscribed components.

For new features and significant updates, Redux should be used instead.

##### StockStore
StockStore is store factory that returns a McFly Store implementing a set of features used by several different models in the Dashboard application. These include:

- Object CRUD
- Object filtering by key
- Object sorting by key
- Data persistence (user actions can be canceled and changes reverted)
- Load state tracking (whether or not the store has received data from the server)

### Redux store
Redux uses a single store, which is built up from many independent reducer functions that handle different actions. Container components — those that determine which child components to render based on application state ­— can then use `connect()` to subscribe to the store, typically with `mapStateToProps()` and `mapDispatchToProps()` functions used to filter out just the data and actions that the Component needs. Using this standard Redux pattern, we pass only the props needed by the immediate child components. This minimizes the amount of rendering, since a React component re-renders whenever its props change.

### Components
Components are the view layer of the JS application. They contain HTML markup and methods that trigger Actions based on user input.

##### High-order components
[High-order components](/app/assets/javascripts/components/high_order) are essentially wrappers for passed components. [This post](https://medium.com/@dan_abramov/mixins-are-dead-long-live-higher-order-components-94a0d2f9e750) describes the idea very well. They are not polymorphic classes, they are a replacement for mixins. That is, they provide reusable methods or rendering patterns to the components that they wrap without violating idiomatic React (as mixins do).

The [Conditional component](/app/assets/javascripts/components/high_order/conditional.jsx) is a simple example: it contains all of the logic for conditionally rendering a component based on a boolean prop. This means we can make any component render based on a boolean without repeating that logic. For example, adding this functionality to the Select component is as simple as changing

	module.exports = Select
to

	module.exports = Conditional(Select)

and passing a `show` parameter to any Select used in our application.

##### Common components
Common components are utilities used throughout the application. These include inputs and modals, among others. They are not special components, they just don't belong to a specific part of the application.

### Utils
Utils include several different helpers for our application and two of them are worth an explanation.

#### Router
The [router.jsx](/app/assets/javascripts/utils/router.jsx) file contains an implementation of [React Router](https://github.com/rackt/react-router). Here we define handlers for different URL paths and structure a hierarchy that allows components to optionally wrap other components based on the URL. As of this writing the React Router library is undergoing some big restructuring for a 1.0 push but documentation for the current version [can be found here](http://rackt.github.io/react-router/).

The Router component is the root of the entire React component tree, and is where the Redux store is defined and injected into the app.

#### API
The [api.js](/app/assets/javascripts/utils/api.js) file contains all AJAX requests for the application that connect back to the app server. Many methods are named according to their  purpose excepting the `fetch` and `modify` methods. These are written to be widely reused by `ServerActions` and require some extra hand-holding to ensure that the proper endpoint is reached.

## Yarn dependency management
When dependencies need to be added or updated, do so using Yarn — for example, `yarn add <package_name>`. This will automatically update the yarn.lock file.

[Back to README](../README.md)

## Front end Technology

The dashboard front end is primarily built using React.js, written in Javascript and JSX. What follows is an overview of how data moves through the app and some more general resources for understanding the stack.

The stylesheet language used is Stylus along with its Rupture utility.
### Resources
- [Thinking in React](https://facebook.github.io/react/docs/thinking-in-react.html)
- [Redux docs](http://redux.js.org/)
- [Getting Started with Redux](https://egghead.io/courses/getting-started-with-redux)
- [React DnD](http://gaearon.github.io/react-dnd/) - The library used for drag-and-drop interactions on the timeline
- [Stylus](https://github.com/stylus/stylus/)
- [Rupture](https://jescalan.github.io/rupture/) - A utility for working with media queries in stylus.

### Actions
Actions are exactly what they sound like: any impactful front end user action should trigger a Redux action that can be received and acted upon by a reducer.

New features should rely on actions in the form of plain objects that are dispatched to the Redux store and handled via reducers. Redux actions may use Thunk middleware to handle async events like API requests.

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
The [routes.jsx](/app/assets/javascripts/components/util/routes.jsx) file contains an implementation of [React Router](https://github.com/rackt/react-router). Here we define handlers for different URL paths and structure a hierarchy that allows components to optionally wrap other components based on the URL. As of January 2019 we have updated to React Router v4, which allows for routes to be present across the entire application. The `routes.jsx` file is just the entrypoint for routing.

The `routes.jsx` file is used within [app.jsx](/app/assets/javascripts/components/app.jsx) component, which is the root of the entire React component tree, and is where the Redux store is defined and injected into the app.

#### API
The [api.js](/app/assets/javascripts/utils/api.js) file contains many of the AJAX requests for the application that connect back to the app server. These AJAX requests are gradually being moved to the actions files.

## Yarn dependency management
When dependencies need to be added or updated, do so using Yarn — for example, `yarn add <package_name>`. This will automatically update the yarn.lock file.

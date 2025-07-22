[Back to README](../README.md)

## Future Improvements & Features

### "What's Changed"
We would like to present users with a summary of important items that have changed in the last week and, if possible, since they last signed in. This is not feasible without a robust caching layer.

Redis can provide a [low-level key/value caching implementation](http://aurelien-herve.com/blog/2015/01/21/awesome-low-level-caching-for-your-rails-app/) for this feature and would allow us to remove the caching columns from our MySQL database.

#### Updating
- Whenever a `revision` is saved the corresponding `user` is `touched`.
- Whenever a `user` is saved all corresponding `courses_users` are `touched`.
- Whenever a `courses_users` is saved the corresponding `course` is `touched`.

#### Fetching
- Whenever a `course` needs to display total revisions it checks for the existence of a redis key using its current `updated_at` value. If that doesn't exist, it gets the number of revisions from each `courses_users`.
- Each `courses_users` checks for the existence of a redis key using its current `updated_at` value. If that doesn't exist, it gets the number of revisions from each `user`.
- Each `user` checks for the existence of a redis key using its current `updated_at` value. If that doesn't exist, it calculates and saves a revision count.


Example: articles store data snapshots in an ordered Redis set with the key `article.<ID>.<DATA_TYPE>`. Whenever a new revision is added to that article a new entry is added to the ordered set with the `score` being a timestamp and the `value` being the added view or character count. Later, when we want to see the number of views between two dates, we can query this ordered set using those dates and sum all values returned.

## Javascript Overview - Things which could be improved

While there is potentially a lot to discuss, I'll try and focus on what I think are the most important issues with our JS side of the stack.

## React

### Strict Mode

We're using React 17 and the upgrade to 18 would be a bit of a pain if we decide to enable [Strict Mode](https://reactjs.org/docs/strict-mode.html). We don't have it enabled currently and enabling it would require us to(among other things) remove all UNSAFE component methods from our code. This unfortunately is a lot harder to do than it sounds since there isn't a one to one mapping between safe and UNSAFE methods.

There's also the fact that in React 18, enabling strict mode mounts the component twice to discover missing or bad cleanup logic in our components. See [Bug: useEffect runs twice on component mount (StrictMode, NODE_ENV=development)](https://github.com/facebook/react/issues/24502) for details but in a nutshell, this means that we can no longer fetch data inside of `useEffect` or `componentDidMount` because it'll send the network request twice.

The way the React team recommends to solve it is by adding a cleanup logic to the `useEffect` hook

```js
useEffect(() => {
  let ignore = false
  fetchStuff().then((res) => {
    if (!ignore) setResult(res)
  })
  return () => {
    ignore = true
  }
}, [])
```

However, this isn't straightforward with `componentDidMount` and given that the majority of our data fetching takes place inside of class based components, its not clear how to solve this easily.

We could of course decide to not enable Strict Mode at all since it doesn't really add anything to our application but it might catch otherwise hard to find bugs.

### Testing

We use Enzyme for testing our React components. However, Enzyme is yet to support even React 17. The issue requesting support was raised in Aug 2020 and [is still open](https://github.com/enzymejs/enzyme/issues/2429).

We use an [adapter package](https://www.npmjs.com/package/@wojtekmaj/enzyme-adapter-react-17) to make everything work, but given the changes introduced with React 18 its unlikely that this or any future adapter package will be able to work. Then there's the creator of the adapter package himself [declaring Enzyme "dead" and shutting down all hopes of an adapter for React 18](https://dev.to/wojtekmaj/enzyme-is-dead-now-what-ekl)

Given how fragile the React tests are and the fact that they rarely actually find bugs, it might make sense to remove them altogether and instead just use rspec everywhere(which we do for a majority of the routes). Migrating to another testing library like [RTL](https://testing-library.com/docs/react-testing-library/intro/) is also an option but one that is probably not worth the effort.

### React Router

React Router 6 doesn't support class based components. Wrapping these components with a functional helper component works but creates a lot of boilerplate and makes it hard to navigate the dev tools. Converting all components which currently use the `withRouter` helper(`app/assets/javascripts/components/util/withRouter.jsx`) to functional components would help simplify things.

Converting these components while repetitive is nonetheless not that straightforward. Here's a couple of things you should keep in mind

1. If the component uses Redux, replace the [`connect`](https://react-redux.js.org/api/connect) API with the `useSelector` and `useDispatch` hooks. The documentation says that while `connect` still works, the use of hooks is recommended since it is easier to read and follow.

2. Instead of accessing the route params from the `this.props`, use the `useParams` hook. Same for `useLocation`. If the component parses or manipulates the search params, use the `useSearchParams` hook instead of doing it manually.

As an example, you can take a look at `app/assets/javascripts/training/components/training_slide_handler.jsx` which I converted to a functional component.

### Create React Class

Before ES6 classes were a thing, the way to create React components was using the `create-react-class` API. This API is now not recommended and has been moved to a different package [`create-react-class`](https://www.npmjs.com/package/create-react-class). Unfortunately, we still make heavy use of this - not only does this add to the bundle size, but it also makes it a lot harder to integrate with other libraries - as mentioned, React Router doesn't support anything but functional components.

Similarly, a recent update to React-DND removed everything but the hooks based API(which can neither be used with class based components nor with ones created using `create-react-class`).

Slowly but surely, rewriting these components as functional ones will help simplify the code and make it easier to maintain and add features to.

## Jest

As of the time of writing, [Jest support for ESM is still "_experimental_"](https://github.com/facebook/jest/issues/9430). This means that even though our production bundle uses ESM, for testing, we convert everything to CJS. However, a lot of package we use are ESM only and we have to resort to a babel plugin to convert them to CJS.

While this does work majority of the time, it still isn't perfect and some ESM only packages won't work. The packages which we convert to CJS are listed in the jest config

```js
transformIgnorePatterns: [
  '/node_modules/(?!@react-dnd|react-dnd|dnd-core|react-dnd-html5-backend|lodash-es|i18n-js)',
]
```

That list is becoming longer and longer as more and more packages only provide ESM versions. Even if we were to opt in to the experimental ESM support, we would first have to update Jest(we currently use version 26)

I have tried attempting the upgrade but couldn't get ESM to play nicely with Jest. Perhaps the support is better when you're reading this, but if we do get rid of the React component tests, it might not be that difficult to replace Jest with something that works better with ESM.

## Reducing Bundle Size

At the time of writing, the bundle size of `vendors.js`(ie, the size of our dependencies) is `1.27MB`. To find which packages contribute the most to the bundle size, you can run `yarn analyze` which will generate a report and open it in your browser.

Right now, one of the biggest contributors to the bundle size is [`velocity.js`](https://www.npmjs.com/package/velocityjs) and [`parsley.js`](https://www.npmjs.com/package/parsleyjs). Both of these packages are only used by the Survey Routes, which is heavily reliant on JQuery and doesn't use much(if any) React.

Combined, both of them take up about `90KB`. When we do rewrite they survey route to use React instead, we will probably be able to get rid of these packages altogether in favor of more modern libraries.

Another potential package to remove is [`list.js`](https://www.npmjs.com/package/list.js). This package is used by server rendered lists to handle sorting. By rewriting these lists to React, we can reclaim this space. Some of these lists have already been converted in the following PRs -

1. [convert course lists to JSX](https://github.com/WikiEducationFoundation/WikiEduDashboard/pull/5039)

2. [Convert campaigns list to JSX](https://github.com/WikiEducationFoundation/WikiEduDashboard/pull/5026)

Both of these PRs should give you an idea about how you would go about doing the conversion.

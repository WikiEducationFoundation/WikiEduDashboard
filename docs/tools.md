[Back to README](../README.md)

## Tools & Integrations

#### Error Logging: [Sentry](https://github.com/getsentry/sentry)
You'll need access to a Sentry server to use this functionality; add the Sentry DSN to `config/application.yml`.

#### Bundle Analysis: [Webpack](https://webpack.js.org/)
To generate the `stats.json` file that's needed to analyze the Webpack bundle, do the following:

For production:
```
npx webpack --mode production --profile --json > stats.json
```

For development:
```
npx webpack --mode development --profile --json > stats.json
```

After generating the `stats.json`, the bundle size could be analyzed by uploading the generated file at any of the mentioned sites [here.](https://webpack.js.org/guides/code-splitting/#bundle-analysis) To know more about how the `stats.json` looks like, head over to https://webpack.js.org/api/stats/ or you could simply run the command and have a look yourself.
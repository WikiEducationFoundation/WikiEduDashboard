[Back to README](../README.md)

## Deployment to Heroku

1. Install [Heroku Toolbelt](https://toolbelt.heroku.com/)
2. `heroku create <my-dashboard-app-name>`
3. `heroku addons:create cleardb:ignite`
4. Copy value of: `heroku config | grep CLEARDB_DATABASE_URL`
5. `heroku config:set DATABASE_URL=<value-from-step-4>` You may get an error if postgres addon was installed. If so remove the addon via the heroku dashboard and try again.
6. `heroku buildpacks:add heroku/ruby`
7. `heroku buildpacks:add https://github.com/krry/heroku-buildpack-nodejs-gulp-bower.git` <https://github.com/krry/heroku-buildpack-nodejs-gulp-bower.git>
8. `git push heroku master`
    - To deploy a separate working branch to heroku run `git push heroku <my-branch>:master`
React = require 'react'
Router = require 'react-router'
Timeline = require("./timeline/timeline.cjsx")

routes = <Router.Route name='main_page' path='*' handler={Timeline}></Router.Route>

Router.run routes, Router.HashLocation, (Handler) ->
  React.render(React.createFactory(Handler)(), document.getElementById('timeline'))
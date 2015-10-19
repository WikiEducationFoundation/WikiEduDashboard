# jsdom = require 'jsdom'
# # move into beforeEach and flip global.window.close on to improve
# # cleaning of environment during each test and prevent memory leaks
# document = jsdom.jsdom('<html><body></body></html>')
#
# beforeEach ->
#   global.document = document
#   global.window = document.parentWindow
#
# afterEach ->
#   # setting up and closing a "window" every run is really heavy
#   # it prevents contamination between tests and prevents memory leaks
#   # global.window.close()

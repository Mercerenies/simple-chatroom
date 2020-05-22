
This is just a very basic chat server, used for learning purposes. It
requires the Coffeescript compiler, a Ruby interpreter, and the Ruby
gems Sinatra and Thin.

Compile the client-side scripts with `rake build`, and run with `rake
run`. As per the Sinatra docs, make sure to set the `APP_ENV`
environment variable to `production` if you want to be able to connect
from other devices. Runs on `localhost:4567` by default.

Features:
 + Simple messaging among any clients connected to the server.
 + Customizable nicknames.
 + A notification when someone enters or leaves the room.

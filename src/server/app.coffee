http           = require "http"
socketio       = require "socket.io"
ioClient       = require "socket.io-client"

SERVICE_NAME = "person-generator"

log       = require "./lib/log"
Generator = require "./lib/Generator"
Service   = require "./models/service-model"

# server without a handler we do not need to serve files
server    = http.createServer null
io        = socketio.listen server

# fixed location of service registry
servRegAddress = "http://localhost:3001"

# collection of client sockets
sockets = []

# create a generator of data
persons = new Generator [ "first", "last", "gender", "birthday", "age", "ssn"]

# distribute data over the websockets
persons.on "data", (data) ->
  data.timestamp = Date.now()
  # filter some data
  # if(data.gender == 'Male')
    # return
  # if(data.age > 35)
    # return
  socket.emit "dataGenerated", data for socket in sockets
persons.start()

# websocket connection logic
io.on "connection", (socket) ->
  # add socket to client sockets
  sockets.push socket
  log.info "Socket connected, #{sockets.length} connection(s) active"

  # disconnect logic
  socket.on "disconnect", ->
    # remove socket from client sockets
    sockets.splice sockets.indexOf(socket), 1
    log.info "Socket disconnected, #{sockets.length} connection(s) active"

# connect to the service registry
serviceRegistry = ioClient.connect servRegAddress,
  "reconnection": true

# when we are connected to the registry start the service
serviceRegistry.on "connect", (socket) ->
  # let the os choose a random port
  server.listen 0
  serviceRegistry.emit "service-up",
    name: SERVICE_NAME
    port: server.address().port

  log.info "Listening on port", server.address().port

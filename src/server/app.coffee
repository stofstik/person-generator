http           = require "http"
socketio       = require "socket.io"
mongoose			 = require "mongoose"

log       = require "./lib/log"
Generator = require "./lib/Generator"
Service   = require "./models/service-model"

# server without a handler we do not need to serve files
server    = http.createServer null
io        = socketio.listen server

mongoAddress = "mongodb://localhost:27017/Services"

# init mongo status logging
db = mongoose.connection
db.on 'connected', ->
	log.info "connected to mongodb"
db.on 'connecting', ->
	log.info "connecting to mongodb"
db.on 'error', (err) ->
	console.error err
	log.info "error connecting to mongodb"
db.on 'disconnected', ->
	log.info "disconnected from mongodb"

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

# start the server
mongoose.connect mongoAddress
# let the os choose a random port
server.listen 0
# save the service info in the db
Service.findOneAndUpdate
	name: Service.SERVICE_NAME
	{ name: Service.SERVICE_NAME, port: server.address().port }
	upsert:							 true
	returnNewDocument: 	 true
	setDefaultsOnInsert: true
	(err, data) ->
		if(err)
			return console.error err
		log.info "saved service: %s @ %s", Service.SERVICE_NAME, server.address().port

log.info "Listening on port", server.address().port

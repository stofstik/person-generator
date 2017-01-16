# required modules
_              = require "underscore"
async          = require "async"
http           = require "http"
express        = require "express"
path           = require "path"
methodOverride = require "method-override"
socketio       = require "socket.io"
errorHandler   = require "error-handler"
mongoose 			 = require "mongoose"

# randomInt = require "./random-int"
log       = require "./lib/log"
Generator = require "./lib/Generator"
Service   = require "./models/service-model"

app       = express()
server    = http.createServer app
io        = socketio.listen server

mongoAddress = "mongodb://localhost:27017/Services"

# init DB
db = mongoose.connection
db.on 'connecting', ->
	log.info "connecting to mongodb"
db.on 'error', ->
	log.info "error connecting to mongodb"
db.on 'disconnected', ->
	log.info "disconnected from mongodb"
	setTimeout ->
		mongoose.connect mongoAddress, { server: { auto_reconnect: true } }
	, 5000

# collection of client sockets
sockets = []

# create a generator of data
persons = new Generator [ "first", "last", "gender", "birthday", "age", "ssn"]

# distribute data over the websockets
persons.on "data", (data) ->
	data.timestamp = Date.now()
	socket.emit "dataGenerated", data for socket in sockets

persons.start()

# websocket connection logic
io.on "connection", (socket) ->
	# add socket to client sockets
	sockets.push socket
	log.info "Socket connected, #{sockets.length} client(s) active"

	# disconnect logic
	socket.on "disconnect", ->
		# remove socket from client sockets
		sockets.splice sockets.indexOf(socket), 1
		log.info "Socket disconnected, #{sockets.length} client(s) active"

# start the server
mongoose.connect mongoAddress, { server: { auto_reconnect: true } }
server.listen 0 # let the os choose a random port
Service.findOne { name: "person-generator"}, (err, data) ->
	if(err)
		return console.log err
	if(data)
		data.update { port: server.address().port }, (err) ->
			if(err)
				console.log err
			else
				console.log "updated"
	else
		Service = new Service
			name: "person-generator"
			port: server.address().port
		Service.save (err) ->
			if(err)
				console.log err
			else
				console.log "saved"

log.info "Listening on port", server.address().port

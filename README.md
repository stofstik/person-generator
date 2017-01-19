# Person Generator Service

## WIP

### About
An assignment for a job opening.  
Starts on a random port and registers with a service registry.  
https://github.com/stofstik/service-registry  
Generates person data each 1000ms and emits it to connected sockets.  
If another service wants to connect to us, it will ask the service-registry for our port.

### Installation
- `npm install -g gulp`
- `npm install`
- `gulp`

Make sure you have https://github.com/stofstik/service-registry running.

### Credits
- <a href="https://www.viriciti.com/">ViriCiti</a>
- Generator extracted from: https://github.com/viriciti/example-application

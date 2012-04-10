process.title = 'server-fixture'

var HTTP = require('http')
  , port = process.argv[2]

var server = HTTP.createServer(function (req, res) {
});

server.listen(port, 'localhost', function () {
    var addr = server.address()
      , msg = "http server started on "
    console.log(msg + addr.address +":"+ addr.port);
});

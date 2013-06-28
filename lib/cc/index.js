var makeSetup = require("./makeSetup");
var grantToken = require("./grantToken");

var grantTypes = "client_credentials";
var reqPropertyName = "clientId";

module.exports = makeSetup(grantTypes, reqPropertyName, grantToken);

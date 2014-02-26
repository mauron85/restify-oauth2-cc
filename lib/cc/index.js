var grantToken = require("./grantToken");
var grantTypes = "client_credentials";
var reqPropertyName = "user";

var requiredHooks = ["grantClientToken", "authenticateToken"];

function setup(
  grantTypes, reqPropertyName, grantToken) {
  var errorSenders =
    require("./makeErrorSenders")(grantTypes);
  var handleAuthenticatedResource =
    require("./makeHandleAuthenticatedResource")(
      reqPropertyName, errorSenders);
  return function(server, options) {
    if (typeof options.hooks !== "object" || options.hooks === null) {
      throw new Error("Must supply hooks.");
    }
    requiredHooks.forEach(function (hookName) {
      if (typeof options.hooks[hookName] !== "function") {
        throw new Error("Must supply " + hookName + " hook.");
      }
    });
    options = options || {};
    options.endpoint = options.endpoint || '/token';
    options.realm = options.realm || 'Authenticated Realm';
    options.expires = options.expires || Infinity;
    // Allow `expires: Infinity` (like above), but translate it into `undefined` so that `JSON.stringify`
    // omits it entirely when we write out the response as `JSON.stringify({ expires_in: expires, ... })`.
    if (options.expires === Infinity) {
      options.expires = undefined;
    }
    server.post(options.endpoint, function (req, res, next) {
      grantToken(req, res, next, options);
    });
    server.use(function(req, res, next) {
      res.sendUnauthorized = function (message) {
        errorSenders.authorizationRequired(res, options, message);
      };
      if (req.method === "POST" && req.path() === options.endpoint) {
        // This is handled by the route installed above, so do nothing.
        next();
      }else if(req.authorization.scheme) {
        handleAuthenticatedResource(req, res, next, options);
      }else {
        req[reqPropertyName] = null;
        next();
      }
    });
  };
};


module.exports = setup(grantTypes, reqPropertyName, grantToken);

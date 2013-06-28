var _ = require("underscore");
var requiredHooks = ["grantClientToken", "authenticateToken"];

module.exports = function makeSetup(
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
    options = _.defaults(options, {
      endpoint: "/token",
      realm: "Authenticated Realm",
      tokenExpirationTime: Infinity
    });
    // Allow `tokenExpirationTime: Infinity` (like above), but translate it into `undefined` so that `JSON.stringify`
    // omits it entirely when we write out the response as `JSON.stringify({ expires_in: tokenExpirationTime, ... })`.
    if (options.tokenExpirationTime === Infinity) {
      options.tokenExpirationTime = undefined;
    }
    server.get(options.endpoint, function (req, res, next) {
      grantToken(req, res, next, options);
    });
    server.use(function(req, res, next) {
      res.sendUnauthorized = function (message) {
        errorSenders.authorizationRequired(res, options, message);
      };
      if (req.method === "GET" && req.path() === options.endpoint) {
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

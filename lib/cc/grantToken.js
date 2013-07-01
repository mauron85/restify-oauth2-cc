var restify = require("restify");

module.exports = function grantToken(req, res, next, options) {
  function sendOAuthError(errorClass, description) {
    var error = new restify[errorClass + "Error"]({ message: description });
    next(error);
  }
  function sendUnauthorizedError(description) {
    //res.header("WWW-Authenticate", "Basic realm=\"" + description + "\"");
    sendOAuthError("Unauthorized", description);
  }
  if (!req.authorization || !req.authorization.basic) {
    return sendOAuthError("NotAuthorized", "Authorization header is required");
  }
  var key = req.authorization.basic.username;
  var secret = req.authorization.basic.password;
  options.hooks.grantClientToken(key, secret, function (error, token) {
      if (error) {
        return next(error);
      }
      if (!token) {
        return sendUnauthorizedError(
          "Authentication failed, please verify your credentials");
      }
      res.send({
        access_token: token,
        token_type: "Bearer",
        expires_in: options.expires
      });
  });
};

var restify = require("restify");

module.exports = function grantToken(req, res, next, options) {
  function sendOAuthError(errorClass, errorType, errorDescription) {
    //var body = { error: errorType, message: errorDescription };
    var error =
      new restify[errorClass + "Error"](
        { message: errorDescription });
    next(error);
  }
  function sendBadRequestError(type, description) {
    sendOAuthError("BadRequest", type, description);
  }
  function sendUnauthorizedError(description) {
    res.header("WWW-Authenticate", "Basic realm=\"" + description + "\"");
    sendOAuthError("Unauthorized", "invalid_client", description);
  }
  if (!req.authorization || !req.authorization.basic) {
    return sendBadRequestError(
      "BadRequest", "Must include a basic access authentication header");
  }
  var user = req.authorization.basic.username;
  var clientSecret = req.authorization.basic.password;
  options.hooks.grantClientToken(
    user, clientSecret, function (error, token) {
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

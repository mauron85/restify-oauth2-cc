# Restify OAuth2 (cc only)

A fork of [restify-oauth2][restify-oauth2] that removes the
[Resource Owner Password Credentials][ropc] support and makes authentication
token generation a `GET` rather than a `POST` request.

## Unit Tests

```
npm test
```

Runs all the unit and integration tests. All tests from the original repository pass after the modifications listed below.

## Modifications

The following list indicates the differences with the initial implementation.

* Token generation is performed with a GET rather than POST request.
* Removed support for the request body and `grant_type` field.
* `tokenEndpoint` option renamed to `endpoint`.
* `wwwAuthenticateRealm` option renamed to `realm`.
* `tokenExpirationTime` option renamed to `expires`.
* Remove dependency on underscore.
* Remove *oauth2-token link* messages.
* Rename `clientId` to `user`.
* Change various messages to be more professional.
* Make error output consistent with restify error output.

Documentation is available at the [original repository][restify-oauth2].

## Configuration

```js
var restify = require("restify");
var oauth2 = require("restify-oauth2-cc");
var server = restify.createServer({ name: "Web Services", version: "1.0.0" });
server.use(restify.authorizationParser());
oauth2.cc(server, options);
```

## Notes

* Unlike the original implementation the [restify][restify] body parser is not required to use this package.
* The `user` fields name was chosen as it is more consistent with other parts of our real-world application that use [express][express] and [passport][passport]. In addition, in a real application you typically want to assign a complex object (user model) to the request object rather than an identifier, therefore `user` is probably more semantically correct.

[restify]: http://mcavage.github.com/node-restify/
[restify-oauth2]: https://github.com/domenic/restify-oauth2
[cc]: http://tools.ietf.org/html/rfc6749#section-1.3.4
[ropc]: http://tools.ietf.org/html/rfc6749#section-1.3.3
[token endpoint]: http://tools.ietf.org/html/rfc6749#section-3.2
[token-endpoint-success]: http://tools.ietf.org/html/rfc6749#section-5.1
[token-endpoint-error]: http://tools.ietf.org/html/rfc6749#section-5.2
[send-token]: http://tools.ietf.org/html/rfc6750#section-2.1
[token-usage-error]: http://tools.ietf.org/html/rfc6750#section-3.1
[oauth2-token-rel]: http://tools.ietf.org/html/draft-wmills-oauth-lrdd-07#section-3.2
[web-linking]: http://tools.ietf.org/html/rfc5988
[www-authenticate]: http://tools.ietf.org/html/rfc2617#section-3.2.1
[express]: http://expressjs.com/
[passport]: http://passportjs.org/

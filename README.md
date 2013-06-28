# Restify OAuth2 (cc only)

A fork of [restify-oauth2](restify-oauth2) that
removes the *Resource Owner Password Credentials* support and makes authentication
token generation a `GET` rather than a `POST` request.

## Differences

The following list indicates the differences with the initial implementation.

* Token generation is performed with a GET rather than POST request.
* Removed support for the request body and `grant_type` field.
* `tokenEndpoint` option renamed to `endpoint`
* `wwwAuthenticateRealm` option renamed to `realm`
* `tokenExpirationTime` option renamed to `expires`

Documentation is available at the [original repository](restify-oauth2).

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

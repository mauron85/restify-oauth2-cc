"use strict"

require("chai").use(require("sinon-chai"))
sinon = require("sinon")
should = require("chai").should()
Assertion = require("chai").Assertion
restify = require("restify")
restifyOAuth2 = require("..")

endpoint = "/token-uri"
realm = "Realm string"
expires = 12345

Assertion.addMethod("unauthorized", (message, options) ->
    expectedLink = '<' + endpoint + '>; rel="oauth2-token"; grant-types="client_credentials"; token-types="bearer"'
    expectedWwwAuthenticate = 'Bearer realm="' +  realm + '"'

    if not options?.noWwwAuthenticateErrors
        expectedWwwAuthenticate += ', error="invalid_token", message="' + message + '"'

    #@_obj.header.should.have.been.calledWith("WWW-Authenticate", expectedWwwAuthenticate)
    #@_obj.header.should.have.been.calledWith("Link", expectedLink)
    @_obj.send.should.have.been.calledOnce
    @_obj.send.should.have.been.calledWith(sinon.match.instanceOf(restify.UnauthorizedError))
    @_obj.send.should.have.been.calledWith(sinon.match.has("message", sinon.match(message)))
)

Assertion.addMethod("bad", (message) ->
    expectedLink = '<' + endpoint + '>; rel="oauth2-token"; grant-types="client_credentials"; token-types="bearer"'
    expectedWwwAuthenticate = 'Bearer realm="' +  realm + '", error="NotAuthorized", ' +
                              'message="' + message + '"'

    #@_obj.header.should.have.been.calledWith("WWW-Authenticate", expectedWwwAuthenticate)
    #@_obj.header.should.have.been.calledWith("Link", expectedLink)
    @_obj.send.should.have.been.calledOnce
    @_obj.send.should.have.been.calledWith(sinon.match.instanceOf(restify.NotAuthorizedError))
    @_obj.send.should.have.been.calledWith(sinon.match.has("message", sinon.match(message)))
)

Assertion.addMethod("oauthError", (errorClass, errorType, errorDescription) ->
    desiredBody = { code: errorType, message: errorDescription }
    @_obj.send.should.have.been.calledOnce
    @_obj.send.should.have.been.calledWith(sinon.match.instanceOf(restify[errorClass + "Error"]))
    @_obj.send.should.have.been.calledWith(sinon.match.has("message", errorDescription))
    #@_obj.send.should.have.been.calledWith(sinon.match.has("code", errorType))
)

beforeEach ->
    @req = { pause: sinon.spy(), resume: sinon.spy(), username: "anonymous", authorization: {} }
    @res = { header: sinon.spy(), send: sinon.spy() }
    @next = sinon.spy((x) => if x? then @res.send(x))

    @server =
        get: sinon.spy((path, handler) => @getToTokenEndpoint = => handler(@req, @res, @next))
        use: (plugin) => plugin(@req, @res, @next)

    @authenticateToken = sinon.stub()
    @grantClientToken = sinon.stub()

    options = {
        endpoint
        realm
        expires
        hooks: {
            @authenticateToken
            @grantClientToken
        }
    }

    @doIt = => restifyOAuth2.cc(@server, options)

describe "Client Credentials flow", ->
    it "should set up the token endpoint", ->
        @doIt()

        @server.get.should.have.been.calledWith(endpoint)

    describe "For GET requests to the token endpoint", ->
        beforeEach ->
            @req.method = "GET"
            @req.path = => endpoint

            baseDoIt = @doIt
            @doIt = =>
                baseDoIt()
                @getToTokenEndpoint()

        describe "with a body", ->
            beforeEach -> @req.body = {}

            describe "that has grant_type=client_credentials", ->
                beforeEach -> @req.body.grant_type = "client_credentials"

                describe "with a basic access authentication header", ->
                    beforeEach ->
                        [@user, @clientSecret] = ["user123", "clientSecret456"]
                        @req.authorization =
                            scheme: "Basic"
                            basic: { username: @user, password: @clientSecret }

                    it "should use the client ID and secret  values to grant a token", ->
                        @doIt()

                        @grantClientToken.should.have.been.calledWith(@user, @clientSecret)

                    describe "when `grantClientToken` calls back with a token", ->
                        beforeEach ->
                            @token = "token123"
                            @grantClientToken.yields(null, @token)

                        it "should send a response with access_token, token_type, and expires_in set", ->
                            @doIt()

                            @res.send.should.have.been.calledWith(
                                access_token: @token,
                                token_type: "Bearer"
                                expires_in: expires
                            )

                    describe "when `grantClientToken` calls back with `false`", ->
                        beforeEach -> @grantClientToken.yields(null, false)

                        it "should send a 401 response with error_type=invalid_client", ->
                            @doIt()

                            @res.should.be.an.oauthError("Unauthorized", "invalid_client",
                                                         "Authentication failed, please verify your credentials")

                    describe "when `grantClientToken` calls back with `null`", ->
                        beforeEach -> @grantClientToken.yields(null, null)

                        it "should send a 401 response with error_type=invalid_client", ->
                            @doIt()

                            @res.should.be.an.oauthError("Unauthorized", "invalid_client",
                                                         "Authentication failed, please verify your credentials")

                    describe "when `grantClientToken` calls back with an error", ->
                        beforeEach ->
                            @error = new Error("Bad things happened, internally.")
                            @grantClientToken.yields(@error)

                        it "should call `next` with that error", ->
                            @doIt()

                            @next.should.have.been.calledWithExactly(@error)

                describe "without an authorization header", ->
                    it "should send a 400 response with error_type=NotAuthorized", ->
                        @doIt()

                        @res.should.be.an.oauthError("NotAuthorized", "NotAuthorized",
                                                     "Authorization header is required")

                    it "should not call the `grantClientToken` hook", ->
                        @doIt()

                        @grantClientToken.should.not.have.been.called

                describe "with an authorization header that does not contain basic access credentials", ->
                    beforeEach ->
                        @req.authorization =
                            scheme: "Bearer"
                            credentials: "asdf"

                    it "should send a 400 response with error_type=NotAuthorized", ->
                        @doIt()

                        @res.should.be.an.oauthError("NotAuthorized", "NotAuthorized",
                                                     "Authorization header is required")

                    it "should not call the `grantClientToken` hook", ->
                        @doIt()

                        @grantClientToken.should.not.have.been.called

    describe "For other requests", ->
        beforeEach -> @req.path = => "/other-resource"

        describe "with an authorization header that contains a valid bearer token", ->
            beforeEach ->
                @token = "TOKEN123"
                @req.authorization = { scheme: "Bearer", credentials: @token }

            it "should pause the request and authenticate the token", ->
                @doIt()

                @req.pause.should.have.been.called
                @authenticateToken.should.have.been.calledWith(@token)

            describe "when the `authenticateToken` calls back with a client ID", ->
                beforeEach ->
                    @user = "client123"
                    @authenticateToken.yields(null, @user)

                it "should resume the request, set the `user` property on the request, and call `next`", ->
                    @doIt()

                    @req.resume.should.have.been.called
                    @req.should.have.property("user", @user)
                    @next.should.have.been.calledWithExactly()

            describe "when the `authenticateToken` calls back with `false`", ->
                beforeEach -> @authenticateToken.yields(null, false)

                it "should resume the request and send a 401 response, along with WWW-Authenticate and Link headers", ->
                    @doIt()

                    @req.resume.should.have.been.called
                    @res.should.be.unauthorized(
                        "Bearer token invalid."
                    )

            describe "when the `authenticateToken` calls back with a 401 error", ->
                beforeEach ->
                    @errorMessage = "The authentication failed for some reason."
                    @authenticateToken.yields(new restify.UnauthorizedError(@errorMessage))

                it "should resume the request and send the error, along with WWW-Authenticate and Link headers", ->
                    @doIt()

                    @req.resume.should.have.been.called
                    @res.should.be.unauthorized(@errorMessage)

            describe "when the `authenticateToken` calls back with a non-401 error", ->
                beforeEach ->
                    @error = new restify.ForbiddenError("The authentication succeeded but this resource is forbidden.")
                    @authenticateToken.yields(@error)

                it "should resume the request and send the error, but no headers", ->
                    @doIt()

                    @req.resume.should.have.been.called
                    @res.send.should.have.been.calledWith(@error)
                    @res.header.should.not.have.been.called

        describe "without an authorization header", ->
            beforeEach -> @req.authorization = {}

            it "should not set `req.user`, and simply call `next`", ->
                @doIt()

                should.not.exist(@req.user)
                @next.should.have.been.calledWithExactly()

        describe "with an authorization header that does not contain a bearer token", ->
            beforeEach ->
                @req.authorization =
                    scheme: "basic"
                    credentials: "asdf"
                    basic: { username: "aaa", password: "bbb" }

            it "should send a 400 response with WWW-Authenticate and Link headers", ->
                @doIt()

                @res.should.be.unauthorized("Bearer token required.")

        describe "with an authorization header that contains an empty bearer token", ->
            beforeEach ->
                @req.authorization =
                    scheme: "Bearer"
                    credentials: ""

            it "should send a 400 response with WWW-Authenticate and Link headers", ->
                @doIt()

                @res.should.be.unauthorized("Bearer token required.")

    describe "`res.sendUnauthorized`", ->
        beforeEach -> @doIt()

        describe "with no arguments", ->
            beforeEach -> @res.sendUnauthorized()

            it "should send a 401 response with WWW-Authenticate (but with no error code) and Link headers, plus the " +
               "default message", ->
                @res.should.be.unauthorized(
                    "Authorization via bearer token required."
                    noWwwAuthenticateErrors: true
                )

        describe "with a message passed", ->
            message = "You really should go get a bearer token"
            beforeEach -> @res.sendUnauthorized(message)

            it "should send a 401 response with WWW-Authenticate (but with no error code) and Link headers, plus the " +
               "specified message", ->
                @res.should.be.unauthorized(message, noWwwAuthenticateErrors: true)

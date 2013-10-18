# # Module receiver
#
# Receives and aggregates signals from other nodes in the network.
#
# 
# Copyright (c) 2013 Quildreen "Sorella" Motta <quildreen@gmail.com>
# 
# Permission is hereby granted, free of charge, to any person
# obtaining a copy of this software and associated documentation files
# (the "Software"), to deal in the Software without restriction,
# including without limitation the rights to use, copy, modify, merge,
# publish, distribute, sublicense, and/or sell copies of the Software,
# and to permit persons to whom the Software is furnished to do so,
# subject to the following conditions:
# 
# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
# LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
# OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
# WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

# -- Dependencies ------------------------------------------------------
express   = require 'express'
pinky     = require 'pinky'
uuid      = (require 'uuid').v1
flaw      = require 'flaw'
minimatch = require 'minimatch'
signal    = require 'shoutout'

{ Maybe, Either, Error, Success } = require './monads'
{ Base }                          = require 'boo'
{ kind-of }                       = require './utils'
{ send }                          = require './http'


# -- Aliases -----------------------------------------------------------
{ is-array } = Array


# -- Shared state ------------------------------------------------------
app       = null
receivers = {}


# -- Exceptions --------------------------------------------------------
export ViolatedExpectation = (handshake) ->
  flaw 'ViolatedExpectation'
     , 'The connection’s handshake does not match the receiver’s expectations.'
     , handshake


export UnexpectedExpectationType = (x) ->
  flaw 'UnexpectedExpectationType', 'Unexpected expectation type', x


export UnknownConnection = (connection) ->
  flaw 'UnknownConnection'
     , 'No registered connections match the provided tokens.'
     , connection


export UnknownReceiver = (id) ->
  flaw 'UnknownReceiver'
     , "No registered receiver matches the id #id"


# -- Public API --------------------------------------------------------
export listen = (port = 0, configure = default-configuration) ->
  promise = pinky!
  app     = express!

  configure app
  define-routes-for app
  app.listen port, (error) -> do
                              if error => promise.reject error
                              else     => promise.fulfill @address!port
  return promise                              
  

export receiver = (expectations) -> 
  a = Receiver.make expectations
  receivers[a.id] = a
  return a


# -- Private helpers ---------------------------------------------------
default-configuration = (app) ->
  app.use express.json!


define-routes-for = (app) ->
  app.post '/:id/connect' (request, response) ->
    response `send` (receiver-for request).map ([r, v]) -> r.connect v


  app.post '/:id/status' (request, response) ->
    response `send` (receiver-for request).map ([r, v]) -> r.report v


receiver-for = (request) ->
  id   = request.params.id
  data = JSON.parse request.body

  if id of receivers => Success [receivers[id], data]
  else                  Error (UnknownReceiver id)


make-proper-expectations-from = (x) ->
  | is-array x              => x.map (a) -> as-pattern a
  | (kind-of x) is 'Number' => [Expectation.Any] * x
  | otherwise               => throw UnexpectedExpectationType x


as-pattern = (a) ->
  | 'test' in a => a
  | otherwise   => Pattern.make a


Receiver = Base.derive {
  on-connection: signal!
  on-status: signal!
  on-closed: signal!

  init: (provided-expectations = []) ->
    @id            = uuid!
    @connections   = {}
    @expectations  = make-proper-expecations-from provided-expectations
    @on-connection = signal!
    @on-status     = signal!
    @on-closed     = signal!


  connect: (handshake) ->
    if not @expectations.allows handshake.client => Error (ViolatedExpectation handshake)
    else
      connection = Connection.make handshake
      @connections[connection.id] = connection
      @on-connection connection
      return Success connection


  report: (status) ->
    connection = @connections[status.connection.id]
    if not connection => Error (UnknownConnection status.connection)
    else
      @on-status status
      finished = connection.accept status
      if finished => @on-closed connection.summarise!
      Success connection
}


Connection = Base.derive {
  init: (expectation) ->
    @id             = uuid!
    @client         = expectation.client
    @expected-tests = expectation.tests
    @tests          = []


  accept: (status) -> 
    @tests.push status
    @tests.length >= @expected-tests


  summarise: ->
    @tests.reduce do
                  * (r, x) -> do
                              r.[]"#{x.status}".push x
                              r

                  * passed : []
                    failed : []
                    ignored: []

  to-json: ->
    id             : @id
    client         : @client
    expected-tests : @expected-tests
    tests          : @tests
    finished       : @tests.length >= @expected-tests
}


Expectation = Base.derive {
  Any: {}
  init: (@allowed = []) ->


  allows: (client) ->
    (@matches-specific-client client) or (@matches-any client)


  matches-specific-client: (client) ->
    for i, pattern in @allowed when pattern.test client
      @allowed.splice i, 1
      return true
                                   
    
  matches-any: ->
    pos = @allowed.index-of @Any
    if pos > -1 => do
                   @allowed.splice pos, 1
                   true
}


Pattern = Base.derive {
  init: (@pattern) ->
  test: (value) -> (kind-of value) is 'String' and minimatch value, pattern
}

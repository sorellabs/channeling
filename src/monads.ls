# # Module monads
#
# Fantasy-land compatible implementation of common Monads/ADTs
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

{ Base } = require 'boo'


export Maybe = Base.derive {
  isJust: -> true
  isNothing: -> false

  Nothing :     -> Nothing
  of      : (v) -> @derive value: v
  map     : (f) -> @of (f @value)
  chain   : (f) -> f @value
  ap      : (b) -> b.map @value
  orElse  : (f) -> this
}

Nothing = Base.derive {
  isJust: -> false
  isNothing: -> true

  of     :     -> Nothing
  map    : (f) -> this
  chain  : (f) -> this
  ap     : (b) -> b
  orElse : (f) -> f!
}


export Either = Base.derive {
  Left  : (v) -> Left.derive value: v
  Right : (v) -> Either.of v

  isLeft : -> false
  isRight: -> true

  of: (v) -> @derive value: v

  fold: (f, g) ->
    | @isLeft!  => f @value
    | @isRight! => g @value    

  chain: (f) -> @fold do
                      * (l) ~> @Left l
                      * (v) -> f v

  swap: -> @fold do
                 * (l) ~> @Right l
                 * (r) ~> @Left r

  map: (f) -> @chain (v) ~> @of (f v)
    
  bimap: (f, g) -> @fold do
                         * (l) ~> @Left (f l)
                         * (r) ~> @Right (g r)

  ap: (b) -> @chain (f) -> b.map f

  orElse: (f) -> @fold do
                       * (l) -> f l
                       * (r) ~> @Right r
}


Left = Either.derive {
  isLeft : -> true
  isRight: -> false
}

export Error   = Either.Left
export Success = Either.Right

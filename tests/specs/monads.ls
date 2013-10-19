spec   = (require 'hifive')!
assert = require 'assert'
{ Maybe, Either, Success, Error } = require '../../src/monads'

eq = (x, y) --> assert.deepEqual x, y
ok = assert.ok
id = (x) -> x

module.exports = spec '{} Monads' (_, spec) ->
  spec '{} Maybe' (o) ->
     o '.of(x) should return a monad with x as value.' ->
       (Maybe.of 1 .chain id) `eq` 1

     o '.map(f) should return a monad transformed by f.' ->
       (Maybe.of 1 .map (+ 1) .chain id) `eq` 2

     o '.chain(f) should apply f to the value.' ->
       (Maybe.of 1 .chain id) `eq` 1

     o '.ap(b) should apply value to b’s value.' ->
       (Maybe.of id .ap (Maybe.of 1) .chain id) `eq` 1

     o '.orElse(f) should ignore the operation.' ->
       (Maybe.of 1 .or-else (-> 2) .chain id) `eq` 1

  spec '{} Nothing' (o) ->
     Nothing = Maybe.Nothing!
     o '.of(x), .map(f), .chain(f) should return Nothing.' ->
       (Nothing.of 1) `eq` Nothing
       (Nothing.map (-> 1)) `eq` Nothing
       (Nothing.chain (-> 1)) `eq` Nothing

     o '.ap(b) should return b.' ->
       b = Maybe.of 1
       (Nothing.ap b) `eq` b

     o '.orElse(f) should apply f.' ->
       (Nothing.or-else -> 1) `eq` 1

  spec '{} Either' (o) ->
    l = Either.Left 1
    r = Either.Right 2

    o '.of(v) should fulfill the Right value of Either.' ->
      (Either.of 1 .chain id) `eq` 1

    o '.fold(f, g) should apply f to L, g to R.' ->
      (l.fold (+ 1), (+ 1)) `eq` 2
      (r.fold (+ 1), (+ 1)) `eq` 3

    o '.chain(f) should apply f to R, ignore L.' ->
      (l.chain id).value `eq` 1
      (r.chain id) `eq` 2

    o '.swap() should swap both values.' ->
      (l.swap!.chain id) `eq` 1
      (r.swap!.or-else id) `eq` 2

    o '.map(f) should apply f to the right value.' ->
      (l.map (+ 1) .or-else id) `eq` 1
      (r.map (+ 1) .chain id) `eq` 3

    o '.bimap(f, g) maps both values.' ->
      (l.bimap (+ 1), (+ 2) .or-else id) `eq` 2
      (r.bimap (+ 1), (+ 2) .chain id) `eq` 4

    o '.ap(b) applies Right to b’s value.' ->
      (Either.Left  (+ 1) .ap (Maybe.of 1) .or-else id)(1) `eq` 2
      (Either.Right (+ 1) .ap (Maybe.of 1) .chain id) `eq` 2
      
    o '.orElse(f) should apply a value to the left side.' ->
      (l.or-else id) `eq` 1
      (r.or-else id .chain id) `eq` 2
    
    
      

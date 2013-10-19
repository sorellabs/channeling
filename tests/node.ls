hifive   = require 'hifive'
reporter = require 'hifive-tap'
specs    = require './specs'

(hifive.run specs, reporter!).otherwise -> process?.exit 1

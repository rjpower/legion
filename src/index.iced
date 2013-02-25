hash = require './hash'
logging = require './logging'
tablet = require './tablet'
util = require 'util'

for module in [hash, logging, tablet]
  for key, val of module
    if exports[key]?
      util.error "Warning - conflicting exports: #{key} : #{val} and #{exports[key]}"
    exports[key] = val

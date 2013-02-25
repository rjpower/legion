iced_runtime = (require "iced-coffee-script").iced
fs = require "fs"
legion = require "#{__dirname}/../src"
util = require "util"
dash = require "lodash"
assert = require "assert"
require "callsite"

process.on('SIGINT', 
  () -> 
    console.log(new Error().stack)
    process.exit())

class TestAssertion
  constructor: (@cb, @log = [], @finished = false) ->

  push_error: (msg) ->
    frame = __stack[3]
    line = frame.getLineNumber()
    file = frame.getFileName()
    where = "#{file}:#{line}"
    @log.push("#{where} -- error: #{msg}")
    return 'an error occurred.'
  
  ok: (expr) => if !expr? then return @push_error('!ok')
  ifError: (expr) => if expr? then return @push_error('!ifError')
  equals: (a, b) => if a != b then return @push_error("!#{a} == #{b}")
  equal: (a, b) => if a != b then return @push_error("!#{a} == #{b}")
  notEqual: (a, b) => if a == b then return @push_error("!#{a} != #{b}")
  done: () =>
    if not @finished
      @finished = true
      @cb @log

if exports? then assert("This file should not be imported.")

files = fs.readdirSync __dirname
testfiles = []
for f in files
  suffix = /.*\.([^.]+)/.exec(f)[1]
  prefix = f.substring(0, 5)
  f = fs.realpathSync("#{__dirname}/#{f}")
  if f != __filename and prefix == 'test_' and (suffix in ['iced', 'js', 'coffee'])
    testfiles.push(f)

for testfile in testfiles
  console.log "Running tests in: #{testfile}"
  module = require("#{testfile}")
  for testname, testobj of module
    for methodname in dash.methods(testobj)
      if methodname == 'setUp' or methodname == 'tearDown'
        continue
      is_func = !(method && method.constructor && method.call && method.apply)
      method = testobj[methodname]
      console.log("Running test: #{testname}::#{methodname}")
      if testobj.setUp then await testobj.setUp defer()
      await
        helper = new TestAssertion(defer err)
        testobj[methodname] helper
      if err.length > 0 then console.log(err.join("\n"));
      if testobj.tearDown then await testobj.tearDown defer()

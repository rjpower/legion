require 'callsite'
util = require 'util'
dash = require 'lodash'
fs = require 'fs'

{ stackWalk, exceptionHandler } = require('iced-coffee-script').iced 
{AssertionError} = require 'assert'

DEBUG = 1
INFO = 2
WARN = 3
ERROR = 4
FATAL = 5  

pad = (value, digits=2) ->
  v = value.toString()
  while (v.length < digits)
    v = '0' + v
  v

log_msg = (args...) ->
  frame = __stack[2]
  file = frame.getFileName()
  line = frame.getLineNumber()
  ts = new Date()
  msg = dash.map(args, (x) -> util.inspect(x)).join(', ')

  year = pad(ts.getFullYear(), 4)
  month = pad(ts.getMonth(), 2)
  day = pad(ts.getDate(), 2)
  hours = pad(ts.getHours(), 2)
  min = pad(ts.getMinutes(), 2)
  sec = pad(ts.getSeconds(), 2)
  millis = pad(ts.getMilliseconds(), 3)
  util.error "#{year}#{month}#{day}:#{hours}#{min}#{sec}.#{millis} -- #{file}:#{line}: #{msg}"

exports.DEBUG = DEBUG
exports.INFO = INFO
exports.WARN = WARN
exports.ERROR = ERROR
exports.FATAL = FATAL

level = INFO

exports.set_log_level = (l) -> level = l

exports.debug = (args...) -> if level <= DEBUG then log_msg(args...)
exports.info = (args...) -> if level <= INFO then log_msg(args...)
exports.warn = (args...) -> if level <= WARN then log_msg(args...) 
exports.error = (args...) -> if level <= ERROR then log_msg(args...)
exports.fatal = (args...) -> if level <= FATAL then log_msg(args...)
exports.assert = (expr, msg='') ->
  frame = __stack[1]
  file = frame.getFileName()
  lineno = frame.getLineNumber()
  stack = stackWalk()
  if !expr
    log_msg("Assertion #{msg} failed at #{file}:#{lineno}.", stack.join('\n'))
    throw new Assertion("Assertion #{msg} failed at #{file}:#{lineno}")

exports.report_error = (err_list, cb) ->
  if not err_list? then return false
  if dash.isString(err_list) or not err_list.length?
    err_list = [err_list]
  err = dash.find(err_list)
  if err?
    if not err instanceof Error then err = new Error(err)
    log_msg("Error during async call: #{err}")
    cb(err, null)
    return true
  return false


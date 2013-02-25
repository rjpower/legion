util = require 'util'
dash = require 'lodash'
assert = require 'assert'
legion = require '../src'
rpc = require 'framed-msgpack-rpc'
microtime = require 'microtime'

class PingServer extends rpc.SimpleServer
  constructor : (args) ->
    super(args)
    @count = 0
    @last_tick = -1
    @set_program_name "PingServer.0"

  h_ping : (request, handle) =>
    @count++
    
    if @count % 10000 == 0
      now = microtime.nowDouble()
      if @last_tick == -1
        @last_tick = now
      else
        legion.info "Working... #{10000 / (now - @last_tick)}/s"
        @last_tick = now
    handle.result request

if require.main == module
  ping_server = new PingServer
    port : 10001

  legion.info("Listening...")
  await ping_server.listen defer err
  assert !err


util = require 'util'
dash = require 'lodash'
assert = require 'assert'
legion = require '../src'
rpc = require 'framed-msgpack-rpc'
mt = require 'microtime'

if require.main == module
  transport = rpc.createTransport { host: '127.0.0.1', port : 10001 }
  await transport.connect defer err
  assert !err
  
  ping_client = new rpc.Client transport, "PingServer.0"
  assert !err
  
  start = mt.nowDouble()
  for i in [0..10000]
    await
      for j in [0..10]
        ping_client.invoke 'ping', 'Hello!', defer(err, response)
      
    if i % 100 == 0
      diff = mt.nowDouble() - start
      legion.info("Working... #{i * 10} #{i * 10.0 / diff}/s")

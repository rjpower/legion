"use strict"

iced_compiler = require 'iced-coffee-script'
rpc = require "framed-msgpack-rpc"
util = require "util"
leveldb = require "leveldb"
printf = require "printf"
logging = require "./logging"

hash = require "./hash"
_ = require "lodash"

to_dict = (kv_list) ->
  dict = {}
  dict[k] = v for [k, v] in kv_list
  dict

class Cluster extends rpc.SimpleServer
  constructor: (@servers = {}) ->
  h_run: (req, res) ->
    @servers[req.name] = req.server
    server.run()
    res.result null

  h_stop: (req, res) ->
    delete @servers[req.name]
    res.result null

  h_lookup: (req, res) ->
    res.result @servers[name]

class ClusterClient
  constructor: () ->

class Tablet
  constructor: (args) ->
    @filename = args.filename or "/tmp/foo.ldb"
    @iterators = []
    @iter_id = 0
    
  initialize: (cb) ->
    logging.debug('Creating...', @filename)
    await 
      leveldb.open @filename, create_if_missing : true, defer(err, @db)
    cb()
  
  destroy: (cb) ->
    logging.debug('Destroying...', @filename)
    await leveldb.destroy @filename, defer()
    cb(null, null)
  
  put: (req, cb) => 
    await @db.put req.key, req.value, defer err
    return cb(null, null)
    
  get: (req, cb) => 
    await @db.get req.key, defer err, value
    return cb(null, value)
    
  rm: (req, cb) => 
    await @db.del req.key, defer err
    return cb(null, value)
    
  iter_new: (req, cb) =>
    await @db.iterator defer(err, iter)
    await iter.first defer(err)
    @iterators[@iter_id] = iter
    cb(null, @iter_id++)
    
  iter_fetch: (req, cb) =>
    iter = @iterators[req.iter_id]
    if not iter? then return logging.report_error("iterator id: #{req.iter_id} invalid.", cb)
    if not iter.valid() then return cb( null, { kvs: [], done: true})
     
    kv = []
    fetch_size = req.fetch_size || default_fetch_size
    for i in [0..fetch_size - 1]
      [key,value] = iter.current()
      kv[i] = { key, value } 
      await iter.next defer err
      if !iter.valid() then break
    cb(null, { kvs : kv, done: !iter.valid() })

class TabletServer extends rpc.SimpleServer
  for k, v of Tablet
    TabletServer["h_#{k}"] = v


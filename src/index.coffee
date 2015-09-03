redis = require 'redis'
dd = require 'deep-diff'
promise = require 'bluebird'
_ = require 'lodash'

promise.promisifyAll(redis)

factory = (options) ->
  new Storage(options)

factory.middleware = (options) ->
  # provideVariable context.tgUser to context
  storage = new Storage(options)
  (context) ->
    storage.find(context.meta.userId).then (user) ->
      context.tgUser = user


class Storage

  constructor: (options) ->
    @client = redis.createClient(options.redis)

  find: (id) ->
    @client.getAsync(id).then(JSON.parse).then (user) ->
      new User(if user then user else {id: id}, @)

  save: (id, data) ->
    @client.setAsync(id, JSON.stringify(data))


class User

  constructor: (data, storage) ->
    @_data = data
    @_storage = storage
    _.merge(@, data)

  update: (data) ->
    _.merge(@, data)
    @

  save: ->
    ownNames = Object.getOwnPropertyNames(@).filter((n) -> n.indexOf('_') != 0)
    ownProps = _.pick(@, ownNames)
    ownPrevProps = @_data
    promise.try ->
      if dd(ownProps, ownPrevProps)?.length
        @_data = ownProps
        @_storage.save(@id, @_data)


module.exports = factory

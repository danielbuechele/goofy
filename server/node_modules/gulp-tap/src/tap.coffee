ES = require('event-stream')
baseStream = require('stream')

DEBUG = process.env.NODE_ENV is 'development'


###
# Taps into the pipeline and allows user to easily route data through
# another stream or change content.
###
module.exports = (lambda) ->
  id = 1
  cache = {}
  utils = (tapStream, file) ->

    ###
    # Routes through another stream. The filter must not be
    # created. This will create the filter as needed and
    # cache when it can.
    #
    # @param filter {stream}
    # @param args {Array} Array containg arguments to apply to filter.
    #
    # @example
    #   t.through coffee, [{bare: true}]
    ###
    through: (filter, args) ->
      if filter.__tapId
        stream = cache[filter.__tapId]
        cache[filter.__tapId] = null unless stream

      if stream
        #stream.removeAllEvents "error"
      else
        if DEBUG
          if !Array.isArray(args)
            throw new Error("Args must be an array to `apply` to the filter")
        stream = filter.apply(null, args)
        stream.on "error", (err) ->
          tapStream.emit "error", err

        filter.__tapId = ""+id
        cache[filter.__tapId] = stream
        id += 1
        stream.pipe tapStream

      stream.write file
      stream

  modifyFile = (file) ->
    inst = file: file
    obj = lambda(inst.file, utils(this, inst.file), inst)

    # passthrough if user returned a stream
    this.emit('data', inst.file) unless obj instanceof baseStream

  return ES.through(modifyFile)


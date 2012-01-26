#= require ./rest_collection

class Joosy.Resource.REST extends Joosy.Module
  @include Joosy.Modules.Log
  @include Joosy.Modules.Events

  __primaryKey: 'id'

  @entity: (name) -> @::__entityName = name
  @source: (source) -> @::__source = source
  @primary: (primary) -> @::__primaryKey = primary
  @beforeLoad: (action) -> @::__beforeLoad = action

  constructor: (description) ->
    if @constructor.__isId(description)
      @id = description
    else
      @__fillData(description)
      @id = @e[@__primaryKey]

  @entityName: ->
    unless @::hasOwnProperty '__entityName'
      @::__entityName = @name.underscore()
    @::__entityName

  # Returns single entity if int/string given
  # Returns collection if no value or Object (with parameters) given
  @find: (description, callback, options) ->
    if @__isId(description)
      resource = new @(description)
      resource.fetch callback, options
      resource
    else
      resources = new Joosy.Resource.RESTCollection(@, description)
      resources.fetch callback, options
      resources

  fetch: (callback, options) ->
    @constructor.__ajax 'get', @constructor.__buildSource(extension: @id), options, (e) =>
      @__fillData(e)
      callback?(this)

    this

  save: ->

  destroy: (callback, options) ->
    @constructor.__ajax 'delete', @constructor.__buildSource(extension: @id), options, (e) =>
      callback?(this)

    this

  @__isId: (something) -> Object.isNumber(something) || Object.isString(something)

  @__ajax: (method, url, options={}, callback) ->
    $.ajax url, Object.extended(
      type: method
      success: callback
      cache: false
      dataType: 'json'
    ).merge options

  @__buildSource: (options={}) ->
    unless @::hasOwnProperty '__source'
      @::__source = "/" + @entityName().pluralize()

    source = Joosy.buildUrl("#{@::__source}/#{options.extension || ''}", options.params)

  __fillData: (data) ->
    data = Object.extended(data)
    data = @__beforeLoad(data) if @__beforeLoad?

    if Object.isObject(data) && data[@constructor.entityName()] && data.keys().length == 1
      @e = Object.extended data[@constructor.entityName()]
    else
      @e = data
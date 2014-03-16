class Batman.Paginator extends Batman.Object
  _STATES:
    LOADING: "loading"
    READY: "ready"

  @_requestCache: {}
  @clearRequestCache: -> @_requestCache = {}

  constructor: (options={}) ->
    defaults =
      limit: 10
      offset: 0
      prefetch: false
    queryHash = {queryParams: new Batman.Hash(options.queryParams || {})}

    super(Batman.extend(defaults, options, queryHash))
    @set('_state', @_STATES.READY)
    @set('total', 0)

  @::observe 'requestURL', ->
    @_loadRecords()

  @accessor 'modelURL', ->
    url = @get('model.url')
    if url.indexOf(".json") is -1
      url += ".json"
    url = Batman.Navigator.normalizePath("/", url) # make it absolute
    url

  @accessor 'requestURL', ->
    queryString = "offset=#{@get('offset')}&limit=#{@get('limit')}"
    @get('queryParams').forEach (key, value) ->
      queryString += "&#{key}=#{value}"
    if @get('searchTerm')
      queryString += "&q=#{@get('searchTerm')}"
    queryUrl = "#{@get('modelURL')}?#{queryString}"

  @accessor 'searchRegExp', -> new RegExp("(^| )#{@get('searchTerm').replace(' ', '.* ')}", 'i')

  @accessor 'results', ->
    if @get('searchTerm')
      return @_filteredSubSet()
    else
      @_loadRecords()
      @resultSubSet ||= new Batman.SubSet(@get('index'), offset: @get('offset'), limit: @get('limit'))

  _filteredSubSet: ->
    @filteredIndex = @get('index').filter (x) =>
      if @get('searchBy') and @get('searchTerm')
        re = @get('searchRegExp')
        str = "#{(x.get(field) for field in @get('searchBy')).join(" ")}"
        if str.match(re)
          return true
        false
      else
        true
    return new Batman.SubSet(@filteredIndex, offset: @get('offset'), limit: @get('limit'))

  _loadRecords: ->
    url = @get('requestURL')
    if !@_alreadyRequested(url)
      @_requestFromUrl(url)
    else
      @getOrSet 'total', => @_cachedTotal(url)
    if @get('prefetch')
      @_prefetch()
    return undefined

  _prefetch: ->
    prefetchOffset = @get('offset') + @get('limit')
    return if prefetchOffset >= @get('total')
    url = @get('requestURL').replace(/offset=\d+/, "offset=#{prefetchOffset}")
    if !@_alreadyRequested(url)
      @_requestFromUrl(url, trackState: false)

  _requestFromUrl: (url, {trackState}={}) ->
    trackState ?= true
    if trackState
      @set('_state', @_STATES.LOADING)
    Batman.Paginator._requestCache[url] = true
    new Batman.Request
      url: url
      autosend: true
      success: (data) => @_handleJSON(data, url)
      loaded: =>
        if trackState
          @set('_state', @_STATES.READY)

  _alreadyRequested: (url) ->
    !!Batman.Paginator._requestCache[url]

  _cachedTotal: (url) ->
    Batman.Paginator._requestCache[url]

  _handleJSON: (json, url) ->
    if json.total?
      @set 'total', json.total
      recordsJSON = json.records
      Batman.Paginator._requestCache[url] = json.total
    else
      recordsJSON = json
    model = @get('model')
    model.get('loaded').prevent('itemsWereAdded')
    modelPrimaryKey = model.get('primaryKey')
    loadedIds = model.get('loaded').mapToProperty('id')
    addedRecords = []
    for recordJSON in recordsJSON
      if recordsJSON[modelPrimaryKey] not in loadedIds
        record = model.createFromJSON(recordJSON)
        addedRecords.push(record)
    model.get('loaded').allowAndFire('itemsWereAdded', addedRecords, null)

  @accessor 'isLoading', -> @get('_state') is @_STATES.LOADING
  @accessor 'isReady', -> @get('_state') is @_STATES.READY
  @accessor 'total'
  @accessor 'currentPage', -> (@get('offset') / @get('limit')) + 1
  @accessor 'totalPages', -> Math.ceil(@get('total') / @get('limit')) || 0
  @accessor 'firstPage', -> @get('currentPage') is 1
  @accessor 'lastPage', -> @get('currentPage') is @get('totalPages')

  next: ->
    if !@get('lastPage')
      @set('offset', @get('offset') + @get('limit'))
      @resultSubSet.set('offset', @get('offset'))

  prev: ->
    if !@get('firstPage')
      @set('offset', @get('offset') - @get('limit'))
      @resultSubSet.set('offset', @get('offset'))
class Batman.Paginator.View extends Batman.View
  @accessor 'paginator', -> @get('controller.paginator')
  @accessor 'searchTerm',
    get: -> @get('paginator.searchTerm')
    set: (key, value) ->
      @_lastValue = value
      setTimeout =>
          if @_lastValue is value
            @set('paginator.searchTerm', value)
        , 200

  ['currentPage', 'totalPages', 'total', 'firstPage', 'lastPage'].forEach (prop) =>
    # in case your version of batman.js doesn't have delegate...
    @accessor prop, ->  @get('paginator').get(prop)

  next: -> @get('paginator').next()
  prev: -> @get('paginator').prev()

  @accessor 'items', -> @get('paginator.results')
  @accessor 'isLoading', -> if @get('paginator.isLoading') == undefined then true else @get('paginator.isLoading')
  @accessor 'noItemsAtAll', -> !@get('searchTerm') and !@get('isLoading') and @get('totalPages') is 0
  @accessor 'noSearchResults', -> !!@get('searchTerm') and !@get('isLoading') and @get('totalPages') is 0

Batman.App.PaginatorView = Batman.Paginator.View
# - returns a section of a Batman.SetSort from <offset> for <limit>
# - Batman-y: bound to its @base, maintains its view bindings
# new Batman.SubSet(someBatmanSet.sortedBy('created_at'), {offset, limit})
class Batman.SubSet extends Batman.SetProxy
  constructor: (base, {offset, limit}={}) ->
    super(base)
    @set('offset', offset)
    @set('limit', limit)
    @_redefine()
    @

  @::observe 'limit', ->
    @_redefine()
  @::observe 'offset', ->
    @_redefine()

  @accessor 'offset',
    get: -> @_offset || 0
    set: (key, value) -> @_offset = Math.max(value, 0)
  @accessor 'start', -> @get('offset')
  @accessor 'end', -> @get('offset') + @get('limit')

  tracksAnyOf: (indexes) ->
    # is there any chance the SetSort wants these items?
    # return true if you're not sure.
    return true if !indexes.length
    min = Math.min(indexes...)
    max = Math.max(indexes...)
    return true if Batman.typeOf(min) != 'Number' or Batman.typeOf(max) != 'Number'
    return false if min > @get('end') or max < @get('start')
    return true

  _handleItemsAdded: (items, indexes) ->
    if @tracksAnyOf(indexes)
      @_redefine()

  _handleItemsRemoved: (items, indexes) ->
    if @tracksAnyOf(indexes)
      @_redefine()

  _handleItemsModified: (item, newValue, oldValue) ->
    console.warn("Batman.SubSet#_handleItemsModified is not implemented.")
    @_redefine()

  _redefine: ->
    newStorage = @base.toArray().slice(@get('offset'), @get('offset') + @get('limit'))
    removed =
      items:   []
      indexes: []
    added =
      items:   []
      indexes: []

    oldStorage = @get('_storage') || []
    newStorageCopy = newStorage.slice()
    newStorageItems = {}
    (newStorageItems["#{idx}"] = item for item, idx in newStorageCopy)

    for oldItem, oldIdx in oldStorage
      newItem = newStorage.filter((i) -> i.valueOf() is oldItem.valueOf())[0]
      if newItem
        newIdx = newStorage.indexOf(newItem)
        delete newStorageItems["#{newIdx}"]
      else
        removed.items.push oldItem
        removed.indexes.push oldIdx

    for idx, item of newStorageItems
      added.items.push item
      added.indexes.push +idx


    @fire('itemsWereRemoved', removed.items.reverse(), removed.indexes.reverse())
    @_setObserver?.stopObservingItems(removed.items)
    @fire('itemsWereAdded', added.items, added.indexes)
    @_setObserver?.startObservingItems(added.items)
    @set("_storage", newStorage)
    @set('length', newStorage.length)
    @set('last', @at(@get('length')))

  toArray: ->
    @base.registerAsMutableSource?()
    @_storage.slice()

  forEach: (iterator, ctx) ->
    @base.registerAsMutableSource?()
    iterator.call(ctx, e, i, this) for e, i in @_storage
    return

  at: (idx) -> @_storage[idx]

  @accessor 'first',
    get: -> @at(0)
    cache: false

  has: (testItem) ->
    for item in @toArray()
      if item == testItem
        return true
    false

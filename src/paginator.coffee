class Batman.Paginator extends Batman.Object
  @SEARCH_TERM_PARAM = "q"

  # Make a new paginator
  #
  # @param [Object] options The options for the new Paginator
  # @option options [Class] model
  # @option options [Integer] limit
  # @option options [Integer] offset
  # @option options [Boolean] prefetch
  # @option options [Batman.SetSort] index
  constructor: (options={}) ->
    defaults =
      limit: 10
      offset: 0
      prefetch: false
      index: options.model.get('loaded.sortedBy.id')
    queryHash = {queryParams: new Batman.Hash(options.queryParams || {})}

    super(Batman.extend(defaults, options, queryHash))
    @set('_state', @_STATES.READY)
    @set('total', 0)

  @::observe 'requestURL', ->
    @_loadRecords()

  # @property [String]  `model.url`, normalized by adding a leading `/` and a trailing `.json`, if necessary
  @accessor 'modelURL', ->
    url = @get('model.url')
    if url.indexOf(".json") is -1
      url += ".json"
    url = Batman.Navigator.normalizePath("/", url) # make it absolute
    url

  # @property [String]
  @accessor 'requestURL', ->
    queryString = "offset=#{@get('offset')}&limit=#{@get('limit')}"
    @get('queryParams').forEach (key, value) ->
      queryString += "&#{key}=#{value}"
    if @get('searchTerm')
      queryString += "&#{@constructor.SEARCH_TERM_PARAM}=#{@get('searchTerm')}"
    queryUrl = "#{@get('modelURL')}?#{queryString}"

  # @property [Integer] number
  @property 'number'

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

  _STATES:
    LOADING: "loading"
    READY: "ready"

  # @property [Object] requests already made by any paginator, in `url: totalResults` pairs.
  @_requestCache: {}
  @clearRequestCache: -> @_requestCache = {}


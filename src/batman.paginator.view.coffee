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

  ['currentPage', 'totalPages', 'total', 'firstPage', 'lastPage'].forEach (prop) ->
    # in case your version of batman.js doesn't have delegate...
    @accessor prop, ->  @get('paginator').get(prop)

  next: -> @get('paginator').next()
  prev: -> @get('paginator').prev()

  @accessor 'items', -> @get('paginator.results')
  @accessor 'isLoading', -> if @get('paginator.isLoading') == undefined then true else @get('paginator.isLoading')
  @accessor 'noItemsAtAll', -> !@get('searchTerm') and !@get('isLoading') and @get('totalPages') is 0
  @accessor 'noSearchResults', -> !!@get('searchTerm') and !@get('isLoading') and @get('totalPages') is 0

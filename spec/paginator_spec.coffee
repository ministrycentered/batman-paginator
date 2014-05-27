
@resetCache = ->
  Batman.Paginator.clearRequestCache()

@newPaginator = (options={})->
  Batman.Request.setupMockedResponse()
  Batman.Paginator.clearRequestCache()
  index = TestModel.get('loaded.sortedBy.name')
  defaultOptions = {model: TestModel, limit: 15, index, searchBy: ['name'], queryParams: {order_by: "name asc"}}
  options = Batman.extend(defaultOptions, options)
  paginator = new Batman.Paginator(options)
  paginator

describe 'Batman.Paginator', ->
  beforeEach ->
    class window.TestModel extends Batman.Model
      @resourceName: 'tests'
      @url: "api/v1/tests"
      @encode "name", "id"
      @persist Batman.RestStorage

  describe 'prefetch', ->
    beforeEach ->
      @paginator = newPaginator(prefetch: true, limit: 3)
      @paginator.set('total', 9)
      resetCache()
      for name, idx in 'defghijkl'.split('')
        TestModel.createFromJSON({id: idx, name: name})

    it 'automatically requests the next page', ->
      @paginator.get('results')
      expect(Batman.Request.requests).toEqual(2)

    it 'doesnt make a request it already made', ->
      @paginator.get('results')
      @paginator.next()
      expect(Batman.Request.requests).toEqual(3)
      @paginator.prev()
      @paginator.next()
      expect(Batman.Request.requests).toEqual(3)

    it 'doesnt request beyond the last page', ->
      @paginator.get('results')
      @paginator.next()
      @paginator.next()
      expect(Batman.Request.requests).toEqual(3)

  describe 'modelURL', ->
    it "uses url", ->
      expect(newPaginator().get('modelURL')).toEqual("/api/v1/tests.json")

    it "uses resourceName", ->
      delete TestModel.url
      expect(newPaginator().get('modelURL')).toEqual("/tests.json")

    it "makes URL absolute if it isn't absolute", ->
      expect(TestModel.url).not.toMatch(/^\//)
      expect(newPaginator().get('modelURL')).toMatch(/^\//)

    it "adds .json to URL if isn't present", ->
      expect(TestModel.url).not.toMatch(/\.json/)
      expect(newPaginator().get('modelURL')).toMatch(/\.json/)

    it "can not add .json to URL", ->
      Batman.Paginator.APPEND_JSON = false
      expect(TestModel.url).not.toMatch(/\.json/)
      expect(newPaginator().get('modelURL')).not.toMatch(/\.json/)
      # put it back
      Batman.Paginator.APPEND_JSON = true

  describe "requestURL", ->
    it "adds queryParams to URL", ->
      queryPaginator = newPaginator()
      queryPaginator.set('queryParams.key', "value")
      expect(queryPaginator.get('requestURL')).toMatch(/order_by=name(\+|%20| )asc/)
      expect(queryPaginator.get('requestURL')).toMatch(/key=value/)

    it "adds offset and limit to URL", ->
      expect(newPaginator().get('requestURL')).toMatch(/limit=15/)
      expect(newPaginator().get('requestURL')).toMatch(/offset=0/)

    it "customizes the search term param", ->
      queryPaginator = newPaginator()
      Batman.Paginator.SEARCH_TERM_PARAM = "query"
      queryPaginator.set('searchTerm', "something")
      expect(queryPaginator.get('requestURL')).toMatch(/query=something/)
      # put it back:
      Batman.Paginator.SEARCH_TERM_PARAM = "q"

  describe "results", ->
    it "returns a SubSet", ->
      paginator = newPaginator()
      expect(paginator.get('results')).toEqual(jasmine.any(Batman.SubSet))

    it "only fires a request the first time", ->
      resetCache()
      paginator = newPaginator()
      paginator.get('results')
      paginator.get('results')
      expect(Batman.Request.requests).toEqual(1)

    describe 'searching', ->
      beforeEach ->
        for name, idx in ["boat", "crayfish", "dog"]
          m = TestModel.createFromJSON({id: idx, name: name})

      it "filters by searchTerm", ->
        paginator = newPaginator()
        paginator.set('searchTerm', 'do')
        expect(paginator.get('results.length')).toEqual(1)
        expect(paginator.get('results.first.name')).toEqual('dog')
        TestModel.createFromJSON(id: 5, name: "doorknob")
        expect(paginator.get('results.length')).toEqual(2)

      it 'cleans yucky search terms', ->
        paginator = newPaginator()
        paginator.set("searchTerm", 'do\\')
        expect( -> paginator.get('searchRegExp') ).not.toThrow()


  describe "next", ->
    it "loads new records if currentPage < totalPages", ->
      paginator = newPaginator()
      resetCache()
      paginator.get('results')
      expect(Batman.Request.requests).toEqual(1)
      paginator.set('total', 100)
      paginator.next()
      expect(Batman.Request.requests).toEqual(2)

    it "doesn't load new records if currentPage >= totalPages", ->
      paginator = newPaginator()
      resetCache()
      expect(Batman.Request.requests).toEqual(0)
      paginator.get('results')
      expect(Batman.Request.requests).toEqual(1)
      paginator.set('total', 6)
      paginator.next()
      expect(Batman.Request.requests).toEqual(1)

  describe "items get loaded by other means", ->
    beforeEach ->
      for name, idx in ["b", "c", "d"]
        m = TestModel.createFromJSON({id: idx, name: name})
      @paginator = newPaginator()
      @paginator.set('limit', 3)

    it "includes the items in #results, if appropriate", ->
      firstRecord = TestModel.createFromJSON({name: "a", id: 51})
      expect(@paginator.get('results').has(firstRecord))

    it "maintains the sort of its #index", ->
      firstRecord = TestModel.createFromJSON({name: "a", id: 51})
      firstResult = @paginator.get('results.first')
      expect(firstResult.get("name")).toBe("a")

    it "doesn't include the item, if not appropriate", ->
      lastRecord = TestModel.createFromJSON({name: "x", id: 51})
      expect(@paginator.get('index').has(lastRecord)).toBe(true) # it's in the index
      expect(@paginator.get('results').has(lastRecord)).toBe(false) # but not in this subset

  describe 'index', ->
    beforeEach ->
      @recordSet = new Batman.Set
      @paginator = newPaginator(model: TestModel, index: @recordSet, limit: 2, searchBy: 'name', queryParams: {})

      # mock pages one and two
      Batman.Request.addMockedResponse 'GET', '/api/v1/tests.json?offset=0&limit=2', ->
        {response: {total: 4, records: [{id: 1, name: "a"}, {id: 2, name: "b"}]}, status: 200}
      Batman.Request.addMockedResponse 'GET', '/api/v1/tests.json?offset=2&limit=2', ->
        {response: {total: 4, records: [{id: 3, name: "c"}, {id: 4, name: "d"}]}, status: 200}


    it 'defaults to loaded.sortedBy.id', ->
      Batman.Request.setupMockedResponse()
      options = {model: TestModel}
      paginator = new Batman.Paginator(options)
      expect(paginator.get('index')).toEqual(TestModel.get('loaded.sortedBy.id'))

    describe 'loading records into a given set, not `loaded`', ->
      it 'specifies another set', ->
        expect(@paginator.get('index')).toEqual(@recordSet)

      it 'loads them into the set', ->
        results = @paginator.get('results')
        expect(results.mapToProperty('name')).toEqual(['a', 'b'])
        @paginator.next()
        expect(results.mapToProperty('name')).toEqual(['c', 'd'])
        @paginator.prev()
        expect(results.mapToProperty('name')).toEqual(['a', 'b'])
        expect(@recordSet.get('length')).toEqual(4)
        expect(TestModel.get('loaded.length')).toEqual(0)

      it 'doesnt load duplicates', ->
        Batman.Request.addMockedResponse 'GET', '/api/v1/tests.json?offset=0&limit=2&q=b', ->
          {response: {total: 4, records: [{id: 2, name: "b"}]}, status: 200}
        results = @paginator.get('results')
        expect(results.mapToProperty('name')).toEqual(['a', 'b'])
        @paginator.next()
        expect(results.mapToProperty('name')).toEqual(['c', 'd'])
        @paginator.prev()
        expect(results.mapToProperty('name')).toEqual(['a', 'b'])
        @paginator.set('searchTerm', 'b')
        expect(@recordSet.get('length')).toEqual(4)


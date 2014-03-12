class @TestModel extends Batman.Model
  @url: "api/v1/tests"
  @encode "name", "id"

@resetCache = ->
  Batman.Paginator.clearRequestCache()

@newPaginator = (options={})->
  Batman.Request.setupMockedResponse()
  index = TestModel.get('loaded.sortedBy.name')
  defaultOptions = {model: TestModel, limit: 15, index, searchBy: ['name'], queryParams: {order_by: "name asc"}}
  options = Batman.extend(defaultOptions, options)
  paginator = new Batman.Paginator(options)
  paginator

describe 'Batman.Paginator', ->
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
    it "makes URL absolute if it isn't absolute", ->
      expect(TestModel.url).not.toMatch(/^\//)
      expect(newPaginator().get('modelURL')).toMatch(/^\//)
    it "adds .json to URL if isn't present", ->
      expect(TestModel.url).not.toMatch(/\.json/)
      expect(newPaginator().get('modelURL')).toMatch(/\.json/)

  describe "requestURL", ->
    it "adds queryParams to URL", ->
      queryPaginator = newPaginator()
      queryPaginator.set('queryParams.q', "search")
      expect(queryPaginator.get('requestURL')).toMatch(/order_by=name(\+|%20| )asc/)
      expect(queryPaginator.get('requestURL')).toMatch(/q=search/)

    it "adds offset and limit to URL", ->
      expect(newPaginator().get('requestURL')).toMatch(/limit=15/)
      expect(newPaginator().get('requestURL')).toMatch(/offset=0/)

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

    it "filters by searchTerm", ->
      paginator = newPaginator()
      for name, idx in ["boat", "crayfish", "dog"]
        m = TestModel.createFromJSON({id: idx, name: name})
      paginator.set('searchTerm', 'do')
      expect(paginator.get('results.length')).toEqual(1)
      expect(paginator.get('results.first.name')).toEqual('dog')
      TestModel.createFromJSON(id: 5, name: "doorknob")
      expect(paginator.get('results.length')).toEqual(2)


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
      firstResult = @paginator.get('results.first')
      expect(firstResult.get("name")).toBe("a")

    it "doesn't include the item, if not appropriate", ->
      lastRecord = TestModel.createFromJSON({name: "x", id: 51})
      expect(@paginator.get('index').has(lastRecord)).toBe(true) # it's in the index
      expect(@paginator.get('results').has(lastRecord)).toBe(false) # but not in this subset

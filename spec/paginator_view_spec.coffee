
describe 'Batman.Paginator.View', ->
  beforeEach ->
    Batman.currentApp = Batman.App

  it 'is accessible as PaginatorView', ->
    view = new Batman.View
    expect(view.lookupKeypath("PaginatorView")).toBeDefined()
    expect(view.lookupKeypath("PaginatorView")).toBe(Batman.Paginator.View)

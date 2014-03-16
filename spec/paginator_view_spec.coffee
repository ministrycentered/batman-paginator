describe 'Batman.Paginator.View', ->
  it 'is found on window', ->
    view = new Batman.View
    expect(view.lookupKeypath("Batman.Paginator.View")).toBe(Batman.Paginator.View)

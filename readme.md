# Batman.Paginator

A paginator for `Batman.Model`s that use `Batman.RestStorage`. It provides:

- Lazy-loading records from the server
- Adding records to `loaded` or another set
- A built-in view for working with the paginator
- "Text search" by searching records in memory and firing a request to the server with the query
- Page prefetching so nobody has to wait!

Also, a full test suite in `spec/`.

# Setup

- __Include it in your project__:

  Get the source in [CoffeeScript](https://raw.github.com/ministrycentered/batman-paginator/master/dist/batman.paginator.coffee) or [JavaScript](https://raw.github.com/ministrycentered/batman-paginator/master/dist/batman.paginator.js) or [minified JavaScript](https://raw.github.com/ministrycentered/batman-paginator/master/dist/batman.paginator.min.js).

  If you're using Rails:

  ```coffee
  #= require ./path/to/batman.paginator
  ```

- __Set up a model__:

  ```coffee
  class App.Person extends Batman.Model
    @persist Batman.RestStorage # must use RestStorage (or descendent like RailsStorage)
    @url: "api/v1/people" # must have @url, @resourceName, or @storageKey
  ```

- __Set up your API endpoint__:

  The paginator will send a request like this one:

  ```
  GET "#{model.url}#{.json if needed}?offset=#{offset}&limit=#{limit}&#{serialized queryParams}"
  ```
  And it expects a response like this one:

  ```javascript
  {
    "total" : 35
    "records" : [
      { /* your record JSON */},
      { /* your record JSON */},
      { /* your record JSON */}...
    ]
  }
  ```

  Also, if you use `searchTerm`, it will be sent to the server as `?q=your%20search`.

# Usage

- __Use a paginator in the controller:__

  ```coffeescript
  class App.PeopleController extends App.ApplicationController
    index: (params) ->
      @set 'paginator', new Batman.Paginator      # make sure `controller.paginator` is set!
        prefetch: true                                  # pre-load the next page of results
        model: App.Person                               # Batman.Model where it can get the URL
        index: App.Person.get('loaded.sortedBy.name')   # Index to track for pagination
        limit: 10                                       # per page
        offset: 0                                       # defaults to 0
        queryParams: {order_by: 'first_name asc'}       # additional query params for the request to the server
        searchBy: ['first_name', 'last_name']           # field which will be RegExp'ed with `searchTerm`
      @set('people', @get('paginator.results'))
  ```

  `PaginatorView` below looks for `@controller.get('paginator')`, so make sure to define that if you're using `PaginatorView`.

- __Control the Paginator from the view__:

  You wrap your HTML in a `PaginatorView`:

  ```slim
  div data-view='PaginatorView'
    h4 People

    / optional search:
    input type='text' data-bind='searchTerm'

    /show the items:
    ul
      li data-foreach-person="items"
        a data-route='routes.people[person]'
          span.name data-bind="person.name"

    / When an AJAX request is out:
    p data-showif='isLoading' Loading more results...

    / Total was 0:
    p data-showif="noItemsAtAll" Nobody in the database!

    / "< Prev (Page 1 of 10)  Next >"
    div data-hideif="totalPages | equals 1 | or isLoading"
      a data-event-click='prev' data-addclass-inactive='firstPage'
        | < Prev
      span
        span data-bind='currentPage | prepend "(Page "'
        span data-bind='totalPages | prepend " of " | append ")"'
      a data-event-click='prev' data-addclass-inactive='firstPage'
        | Next >
  ```

# API

## Paginator Options

pass to `new Batman.Paginator(options)`:

- __`model` : Model__: The `Batman.Model` subclass being paginated. `model.url` must be defined.
- __`index` : Set__ : The index where the paginator load records. Defaults to `model.get('loaded').sortedBy('id')`. Pass a `Batman.SetSort` to make sure the client paginator sorts things the same way the server sorts them.

  For example, for a paginator sorting by `score`, send `index: App.Player.get('loaded').sortedBy('score')`

- __`limit` : Integer__: Items per page. Sent to the server as `limit`. Default `10`.
- __`offset` : Integer__: Initial offset (for starting at a page other than 0). Default `0`.
- __`queryParams` : Object__: A JS Object containing `param: "value"` pairs. They will be serialized in the paginator's AJAX requests. This is a nice place for `{order: "name asc"}`, for example. Defaults to `{}`.
- __`prefetch` : Boolean__: If true, the paginator will fetch the _next_ page whenever a new page is displayed. For exampele, going to page 2 will cause the paginator to load page 3. Defaults to `false`.
- __`searchBy`: Array of Strings__:

  If you include property names as `searchBy` when instantiating a paginator, it will filter itself by seeing if any of the `searchBy` properties begin with `searchTerm`.

  It will also fire a request with the search term as `Batman.Paginator.SEARCH_TERM_PARAM` (default value `q`) in the query params.

## PaginatorView accessors

You can use these if you wrap HTML with `data-view='PaginatorView'`
__values:__

- `paginator` - Paginator object
- `total`
- `items` - items in current page
- `currentPage`
- `totalPages`
- `firstPage` - page number
- `lastPage` - page number
- `isLoading` - request is outstanding
- `noItemsAtAll` - request finished with no `searchTerm`, total is 0
- `noSearchResults` - request finished with `searchTerm`, total is 0
- `searchTerm` - debounced accessor for filtering on `searchBy` fields. Suitable for inputs.

__functions:__

- `next` - load next page (eg `data-event-click='next'`)
- `prev` - load previous page

# To Do

- publish on Bower
- Proper API Docs
- Extract `RestPaginator` and `MemoryPaginator`

# Contributing

Please do! We're running this in production, so please report any issues and open a pull request if you want to contribute.

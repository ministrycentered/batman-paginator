# Batman.Paginator

A paginator for `Batman.Model`s that use `Batman.RestStorage`. It provides:

- Lazy-loading records from the server
- Tracking the memory map
- A built-in view for working with the paginator
- "Text search" by searching records in memory and firing a request to the server with the query
- Page prefetching so nobody has to wait!

# Usage

## Include it in your project

```coffee
#= require ./path/to/batman.paginator
```

## Set up a model

```coffee
class App.Person extends Batman.Model
  @persist Batman.RestStorage
  @url: "api/v1/people"
```

## Set up your API endpoint

The paginator expects a response like this one:

```json
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

## Use a paginator in the controller

```
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

## Control the Paginator from the view:

You wrap your HTML in a `PaginatorView`:

```slim
div data-view='PaginatorView'
  h4 People
  input type='text' data-bind='searchTerm'

  ul
    li data-foreach-person="items"
      a data-route='routes.people[person]'
        span.name data-bind="checkin.name"

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

# More info

### `searchBy`

If you include property names as `searchBy` when instantiating a paginator, it will filter itself by seeing if any of the `searchBy` properties begin with `searchTerm`. It will also fire a request with the search term as `q` in the query params.


# To Do

- Proper API Docs
- Extract `RestPaginator` and `MemoryPaginator`

# Contributing

Please do! We're (about to start) running this in production, so please report any issues and open a pull request if you want to contribute.

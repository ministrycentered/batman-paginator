
# from batmanjs/batman -> batman/src/platform/testing.coffee:
Batman.Request.setupMockedResponse = ->
  Batman.Request.requests = 0
  Batman.Request.mockedResponses = {}

Batman.Request.addMockedResponse = (method, url, callback) ->
  Batman.Request.mockedResponses["#{method}::#{url}"] ||= []
  Batman.Request.mockedResponses["#{method}::#{url}"].push(callback)

Batman.Request.fetchMockedResponse = (method, url) ->
  callbackList = Batman.Request.mockedResponses?["#{method}::#{url}"]
  return if !callbackList || callbackList.length is 0

  callback = callbackList.pop()
  return callback()

Batman.Request.prototype.send = (data) ->
  Batman.Request.requests += 1
  data ||= @get('data')
  @fire 'loading'

  mockedResponse = Batman.Request.fetchMockedResponse(@get('method'), @get('url'))
  if not mockedResponse
    # console.warn "No Mocked response for #{@get('method')}::#{@get('url')}"
    return
  {status, response, beforeResponse, responseHeaders, responseText} = mockedResponse

  @mixin
    status: status || 200
    response: JSON.stringify(response)
    responseHeaders: responseHeaders || {}

  beforeResponse?(this, data)

  if @status < 400
    @fire 'success', response
  else
    @fire 'error', {response: response, responseText: responseText, status: @status, request: this}

  @fire 'loaded'

Batman.setImmediate = (fn) -> setTimeout(fn, 0)
Batman.clearImmediate = (handle) -> clearTimeout(handle)

# - returns a section of a Batman.SetSort from <offset> for <limit>
# - Batman-y: bound to its @base, maintains its view bindings
# @example New subset
#   new Batman.SubSet(someBatmanSet.sortedBy('created_at'), {offset, limit})
#
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

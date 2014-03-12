window.newLetter = (letter) ->
  new Batman.Object(letter: letter)

window.newSubSet = (options)->
  letters = 'defghijklmnopqrstuvwxyz'.split('')
  array = (newLetter(l) for l in letters )
  baseSet = new Batman.Set(array...)
  baseSetSort = baseSet.get('sortedBy.letter')
  subSet = new Batman.SubSet(baseSetSort, options)
  return [baseSet, baseSetSort, subSet]

describe 'Batman.SubSet', ->
  describe 'base', ->
    it 'tracks the base', ->
      [baseSet, baseSetSort, subSet] = newSubSet(limit: 10)
      letterA = newLetter('a')
      baseSet.add(letterA)
      expect(subSet.get('first').get('letter')).toEqual('a')
      baseSet.remove(letterA)
      expect(subSet.get('first').get('letter')).toEqual('d')

  describe 'offset & limit work together', ->
      [baseSet, baseSetSort, subSet] = newSubSet(limit: 10)
      expect(subSet.mapToProperty('letter').join("")).toEqual("defghijklm")
      subSet.set('limit', 5)
      subSet.set('offset', 5)
      expect(subSet.mapToProperty('letter').join("")).toEqual("ijklm")

  describe 'limit', ->
    it 'causes the subsets length to change', ->
      [baseSet, baseSetSort, subSet] = newSubSet(limit: 10)
      expect(subSet.get('length')).toEqual(10)
      expect(subSet.mapToProperty('letter').join("")).toEqual("defghijklm")
      subSet.set('limit', 6)
      expect(subSet.mapToProperty('letter').join("")).toEqual("defghi")
      expect(subSet.get('length')).toEqual(6)
      subSet.set('limit', 12)
      expect(subSet.get('length')).toEqual(12)
      expect(subSet.mapToProperty('letter').join("")).toEqual("defghijklmno")

  describe 'offset', ->
    it 'enforces > 0', ->
      [baseSet, baseSetSort, subSet] = newSubSet(limit: 10)
      subSet.set('offset', -3)
      expect(subSet.get('offset')).toEqual(0)

    it 'trashes other stuff', ->
      [baseSet, baseSetSort, subSet] = newSubSet(limit: 10)
      for badValue in [undefined, null, 'abc']
        subSet.set('offset', badValue)
        expect(subSet.get('offset')).toEqual(0)

    it 'causes the subsets contents to change', ->
      [baseSet, baseSetSort, subSet] = newSubSet(limit: 10)
      expect(subSet.mapToProperty('letter').join("")).toEqual("defghijklm")
      subSet.set('offset', 5)
      expect(subSet.mapToProperty('letter').join("")).toEqual("ijklmnopqr")
      subSet.set('offset', 1)
      expect(subSet.mapToProperty('letter').join("")).toEqual("efghijklmn")

  describe 'tracksAnyOf', ->
    beforeEach ->
      [@baseSet, @baseSetSort, @subSet] = newSubSet(limit: 10)

    it 'returns true if any member is inside the range', ->
      expect(@subSet.tracksAnyOf([4,15, 21])).toBe(true)

    it 'returns true if cant figure it out', ->
      expect(@subSet.tracksAnyOf([null])).toBe(true)
      expect(@subSet.tracksAnyOf(["x"])).toBe(true)
      expect(@subSet.tracksAnyOf([])).toBe(true)

    it 'returns false if all too big', ->
      expect(@subSet.tracksAnyOf([89,15, 21])).toBe(false)
    it 'returns false if all too small', ->
      @subSet.set('offset', 11)
      expect(@subSet.tracksAnyOf([4,6, 9])).toBe(false)

(function() {
  var __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
    __indexOf = [].indexOf || function(item) { for (var i = 0, l = this.length; i < l; i++) { if (i in this && this[i] === item) return i; } return -1; };

  Batman.SubSet = (function(_super) {
    __extends(SubSet, _super);

    function SubSet(base, _arg) {
      var limit, offset, _ref;
      _ref = _arg != null ? _arg : {}, offset = _ref.offset, limit = _ref.limit;
      SubSet.__super__.constructor.call(this, base);
      this.set('offset', offset);
      this.set('limit', limit);
      this._redefine();
      this;
    }

    SubSet.prototype.observe('limit', function() {
      return this._redefine();
    });

    SubSet.prototype.observe('offset', function() {
      return this._redefine();
    });

    SubSet.accessor('offset', {
      get: function() {
        return this._offset || 0;
      },
      set: function(key, value) {
        return this._offset = Math.max(value, 0);
      }
    });

    SubSet.accessor('start', function() {
      return this.get('offset');
    });

    SubSet.accessor('end', function() {
      return this.get('offset') + this.get('limit');
    });

    SubSet.prototype.tracksAnyOf = function(indexes) {
      var max, min;
      if (!(indexes != null ? indexes.length : void 0)) {
        return true;
      }
      min = Math.min.apply(Math, indexes);
      max = Math.max.apply(Math, indexes);
      if (Batman.typeOf(min) !== 'Number' || Batman.typeOf(max) !== 'Number') {
        return true;
      }
      if (min > this.get('end') || max < this.get('start')) {
        return false;
      }
      return true;
    };

    SubSet.prototype._handleItemsAdded = function(items, indexes) {
      if (this.tracksAnyOf(indexes)) {
        return this._redefine();
      }
    };

    SubSet.prototype._handleItemsRemoved = function(items, indexes) {
      if (this.tracksAnyOf(indexes)) {
        return this._redefine();
      }
    };

    SubSet.prototype._handleItemsModified = function(item, newValue, oldValue) {
      console.warn("Batman.SubSet#_handleItemsModified is not implemented.");
      return this._redefine();
    };

    SubSet.prototype._redefine = function() {
      var added, idx, item, newIdx, newItem, newStorage, newStorageCopy, newStorageItems, oldIdx, oldItem, oldStorage, removed, _i, _j, _len, _len1, _ref, _ref1;
      newStorage = this.base.toArray().slice(this.get('offset'), this.get('offset') + this.get('limit'));
      removed = {
        items: [],
        indexes: []
      };
      added = {
        items: [],
        indexes: []
      };
      oldStorage = this.get('_storage') || [];
      newStorageCopy = newStorage.slice();
      newStorageItems = {};
      for (idx = _i = 0, _len = newStorageCopy.length; _i < _len; idx = ++_i) {
        item = newStorageCopy[idx];
        newStorageItems["" + idx] = item;
      }
      for (oldIdx = _j = 0, _len1 = oldStorage.length; _j < _len1; oldIdx = ++_j) {
        oldItem = oldStorage[oldIdx];
        newItem = newStorage.filter(function(i) {
          return i.valueOf() === oldItem.valueOf();
        })[0];
        if (newItem) {
          newIdx = newStorage.indexOf(newItem);
          delete newStorageItems["" + newIdx];
        } else {
          removed.items.push(oldItem);
          removed.indexes.push(oldIdx);
        }
      }
      for (idx in newStorageItems) {
        item = newStorageItems[idx];
        added.items.push(item);
        added.indexes.push(+idx);
      }
      this.fire('itemsWereRemoved', removed.items.reverse(), removed.indexes.reverse());
      if ((_ref = this._setObserver) != null) {
        _ref.stopObservingItems(removed.items);
      }
      this.fire('itemsWereAdded', added.items, added.indexes);
      if ((_ref1 = this._setObserver) != null) {
        _ref1.startObservingItems(added.items);
      }
      this.set("_storage", newStorage);
      this.set('length', newStorage.length);
      return this.set('last', this.at(this.get('length')));
    };

    SubSet.prototype.toArray = function() {
      var _base;
      if (typeof (_base = this.base).registerAsMutableSource === "function") {
        _base.registerAsMutableSource();
      }
      return this._storage.slice();
    };

    SubSet.prototype.forEach = function(iterator, ctx) {
      var e, i, _base, _i, _len, _ref;
      if (typeof (_base = this.base).registerAsMutableSource === "function") {
        _base.registerAsMutableSource();
      }
      _ref = this._storage;
      for (i = _i = 0, _len = _ref.length; _i < _len; i = ++_i) {
        e = _ref[i];
        iterator.call(ctx, e, i, this);
      }
    };

    SubSet.prototype.at = function(idx) {
      return this._storage[idx];
    };

    SubSet.accessor('first', {
      get: function() {
        return this.at(0);
      },
      cache: false
    });

    SubSet.prototype.has = function(testItem) {
      var item, _i, _len, _ref;
      _ref = this.toArray();
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        item = _ref[_i];
        if (item === testItem) {
          return true;
        }
      }
      return false;
    };

    return SubSet;

  })(Batman.SetProxy);

  Batman.Paginator = (function(_super) {
    __extends(Paginator, _super);

    Paginator.SEARCH_TERM_PARAM = "q";

    Paginator.APPEND_JSON = true;

    function Paginator(options) {
      var defaults, queryHash;
      if (options == null) {
        options = {};
      }
      defaults = {
        limit: 10,
        offset: 0,
        prefetch: false,
        index: options.model.get('loaded.sortedBy.id')
      };
      queryHash = {
        queryParams: new Batman.Hash(options.queryParams || {})
      };
      Paginator.__super__.constructor.call(this, Batman.extend(defaults, options, queryHash));
      this.set('_state', this._STATES.READY);
      this.set('total', 0);
    }

    Paginator.prototype.observe('requestURL', function() {
      return this._loadRecords();
    });

    Paginator.accessor('adapter', function() {
      return this.get('model').prototype._batman.get('storage');
    });

    Paginator.accessor('modelURL', function() {
      var url;
      url = this.url || this.get('adapter').urlForCollection(this.get('model'), {});
      if (this.constructor.APPEND_JSON && url.indexOf(".json") === -1) {
        url += ".json";
      }
      return url;
    });

    Paginator.accessor('requestURL', function() {
      var queryString, queryUrl;
      queryString = "offset=" + (this.get('offset')) + "&limit=" + (this.get('limit'));
      this.get('queryParams').forEach(function(key, value) {
        return queryString += "&" + key + "=" + value;
      });
      if (this.get('searchTerm')) {
        queryString += "&" + this.constructor.SEARCH_TERM_PARAM + "=" + (this.get('searchTerm'));
      }
      return queryUrl = "" + (this.get('modelURL')) + "?" + queryString;
    });

    Paginator.accessor('searchRegExp', function() {
      var escapedString, searchString;
      escapedString = this.get('searchTerm').replace(/[\-\[\]\/\{\}\(\)\*\+\?\.\\\^\$\|]/g, "\\$&");
      searchString = escapedString.replace(' ', '.* ');
      return new RegExp("(^| )" + searchString, 'i');
    });

    Paginator.accessor('results', function() {
      if (this.get('searchTerm')) {
        return this._filteredSubSet();
      } else {
        this._loadRecords();
        return this.resultSubSet || (this.resultSubSet = new Batman.SubSet(this.get('index'), {
          offset: this.get('offset'),
          limit: this.get('limit')
        }));
      }
    });

    Paginator.prototype._filteredSubSet = function() {
      this.filteredIndex = this.get('index').filter((function(_this) {
        return function(x) {
          var field, re, str;
          if (_this.get('searchBy') && _this.get('searchTerm')) {
            re = _this.get('searchRegExp');
            str = "" + (((function() {
              var _i, _len, _ref, _results;
              _ref = this.get('searchBy');
              _results = [];
              for (_i = 0, _len = _ref.length; _i < _len; _i++) {
                field = _ref[_i];
                _results.push(x.get(field));
              }
              return _results;
            }).call(_this)).join(" "));
            if (str.match(re)) {
              return true;
            }
            return false;
          } else {
            return true;
          }
        };
      })(this));
      return new Batman.SubSet(this.filteredIndex, {
        offset: this.get('offset'),
        limit: this.get('limit')
      });
    };

    Paginator.prototype._loadRecords = function() {
      var url;
      url = this.get('requestURL');
      if (!this._alreadyRequested(url)) {
        this._requestFromUrl(url);
      } else {
        this.getOrSet('total', (function(_this) {
          return function() {
            return _this._cachedTotal(url);
          };
        })(this));
      }
      if (this.get('prefetch')) {
        this._prefetch();
      }
      return void 0;
    };

    Paginator.prototype._prefetch = function() {
      var prefetchOffset, url;
      prefetchOffset = this.get('offset') + this.get('limit');
      if (prefetchOffset >= this.get('total')) {
        return;
      }
      url = this.get('requestURL').replace(/offset=\d+/, "offset=" + prefetchOffset);
      if (!this._alreadyRequested(url)) {
        return this._requestFromUrl(url, {
          trackState: false
        });
      }
    };

    Paginator.prototype._requestFromUrl = function(url, _arg) {
      var trackState;
      trackState = (_arg != null ? _arg : {}).trackState;
      if (trackState == null) {
        trackState = true;
      }
      if (trackState) {
        this.set('_state', this._STATES.LOADING);
      }
      Batman.Paginator._requestCache[url] = true;
      return new Batman.Request({
        url: url,
        autosend: true,
        success: (function(_this) {
          return function(data) {
            return _this._handleJSON(data, url);
          };
        })(this),
        loaded: (function(_this) {
          return function() {
            if (trackState) {
              return _this.set('_state', _this._STATES.READY);
            }
          };
        })(this)
      });
    };

    Paginator.prototype._alreadyRequested = function(url) {
      return !!Batman.Paginator._requestCache[url];
    };

    Paginator.prototype._cachedTotal = function(url) {
      return Batman.Paginator._requestCache[url];
    };

    Paginator.prototype._handleJSON = function(json, url) {
      var addedRecords, index, loadedIds, model, modelPrimaryKey, record, recordJSON, recordsJSON, recordsToAdd, _i, _len, _ref;
      if (json.total != null) {
        this.set('total', json.total);
        recordsJSON = json.records;
        Batman.Paginator._requestCache[url] = json.total;
      } else {
        recordsJSON = json;
      }
      model = this.get('model');
      index = this.get('index');
      index.prevent('itemsWereAdded');
      modelPrimaryKey = model.get('primaryKey');
      loadedIds = index.mapToProperty('id');
      recordsToAdd = [];
      for (_i = 0, _len = recordsJSON.length; _i < _len; _i++) {
        recordJSON = recordsJSON[_i];
        if (_ref = recordJSON[modelPrimaryKey], __indexOf.call(loadedIds, _ref) < 0) {
          record = new model;
          record._withoutDirtyTracking(function() {
            return this.fromJSON(recordJSON);
          });
          recordsToAdd.push(record);
        }
      }
      if (addedRecords = index.add.apply(index, recordsToAdd)) {
        return index.allowAndFire('itemsWereAdded', addedRecords, null);
      }
    };

    Paginator.accessor('isLoading', function() {
      return this.get('_state') === this._STATES.LOADING;
    });

    Paginator.accessor('isReady', function() {
      return this.get('_state') === this._STATES.READY;
    });

    Paginator.accessor('total');

    Paginator.accessor('currentPage', function() {
      return (this.get('offset') / this.get('limit')) + 1;
    });

    Paginator.accessor('totalPages', function() {
      return Math.ceil(this.get('total') / this.get('limit')) || 0;
    });

    Paginator.accessor('firstPage', function() {
      return this.get('currentPage') === 1;
    });

    Paginator.accessor('lastPage', function() {
      return this.get('currentPage') === this.get('totalPages');
    });

    Paginator.prototype.next = function() {
      if (!this.get('lastPage')) {
        this.set('offset', this.get('offset') + this.get('limit'));
        return this.resultSubSet.set('offset', this.get('offset'));
      }
    };

    Paginator.prototype.prev = function() {
      if (!this.get('firstPage')) {
        this.set('offset', this.get('offset') - this.get('limit'));
        return this.resultSubSet.set('offset', this.get('offset'));
      }
    };

    Paginator.prototype._STATES = {
      LOADING: "loading",
      READY: "ready"
    };

    Paginator._requestCache = {};

    Paginator.clearRequestCache = function() {
      return this._requestCache = {};
    };

    return Paginator;

  })(Batman.Object);

  Batman.Paginator.View = (function(_super) {
    __extends(View, _super);

    function View() {
      return View.__super__.constructor.apply(this, arguments);
    }

    View.accessor('paginator', function() {
      return this.get('controller.paginator');
    });

    View.accessor('searchTerm', {
      get: function() {
        return this.get('paginator.searchTerm');
      },
      set: function(key, value) {
        this._lastValue = value;
        return setTimeout((function(_this) {
          return function() {
            if (_this._lastValue === value) {
              return _this.set('paginator.searchTerm', value);
            }
          };
        })(this), 200);
      }
    });

    ['currentPage', 'totalPages', 'total', 'firstPage', 'lastPage'].forEach(function(prop) {
      return View.accessor(prop, function() {
        return this.get('paginator').get(prop);
      });
    });

    View.prototype.next = function() {
      return this.get('paginator').next();
    };

    View.prototype.prev = function() {
      return this.get('paginator').prev();
    };

    View.accessor('items', function() {
      return this.get('paginator.results');
    });

    View.accessor('isLoading', function() {
      if (this.get('paginator.isLoading') === void 0) {
        return true;
      } else {
        return this.get('paginator.isLoading');
      }
    });

    View.accessor('noItemsAtAll', function() {
      return !this.get('searchTerm') && !this.get('isLoading') && this.get('totalPages') === 0;
    });

    View.accessor('noSearchResults', function() {
      return !!this.get('searchTerm') && !this.get('isLoading') && this.get('totalPages') === 0;
    });

    return View;

  })(Batman.View);

  Batman.App.PaginatorView = Batman.Paginator.View;

}).call(this);

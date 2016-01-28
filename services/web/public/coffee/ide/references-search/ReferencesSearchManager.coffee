define [
], () ->
	class ReferencesSearchManager
		constructor: (@ide, @$scope) ->

			@$scope.$root._references = @state = keys: []

			@$scope.$on 'document:closed', (e, doc) =>
				if doc.doc_id
				 	entity = @ide.fileTreeManager.findEntityById doc.doc_id
					if entity?.name?.match /.*\.bib$/
						@indexReferences([doc.doc_id], true)

			# When we join the project:
			#   index all references files
			#   and don't broadcast to all clients
			@$scope.$on 'project:joined', (e) =>
				@indexAllReferences(false)

			setTimeout(
				(self) ->
					self.ide.socket.on 'references:keys:updated', (keys) ->
						# console.log '>> got keys from socket'
						self._storeReferencesKeys(keys)
				, 1000
				, this
			)

		_storeReferencesKeys: (newKeys) ->
			if window._ENABLE_REFERENCES_AUTOCOMPLETE != true
				return
			# console.log '>> storing references keys'
			oldKeys = @$scope.$root._references.keys
			@$scope.$root._references.keys = _.union(oldKeys, newKeys)

		indexReferences: (docIds, shouldBroadcast) ->
			opts =
				docIds: docIds
				shouldBroadcast: shouldBroadcast
				_csrf: window.csrfToken
			$.post(
				"/project/#{@$scope.project_id}/references/index",
				opts,
				(data) =>
					# console.log ">> got keys ", data
					@_storeReferencesKeys(data.keys)
			)

		indexAllReferences: (shouldBroadcast) ->
			opts =
				shouldBroadcast: shouldBroadcast
				_csrf: window.csrfToken
			$.post(
				"/project/#{@$scope.project_id}/references/indexAll",
				opts,
				(data) =>
					# console.log ">> got keys ", data
					@_storeReferencesKeys(data.keys)
			)

class Tickers

	constructor: ->
		console.log "Tickers initialized"
		@maps = {}
		this.areaOnChange = false

	fetch: ->

	item: (item_id) ->

	newBattle: ->
		console.log "Show new battle ticker"
		
	newItem: ->
		console.log "Show new item ticker if possible"

	battle: (enemy_id, background, map_id) ->
		$.post '/users/update_map', window.game.lastMapPositions
		window.game.updateMapPositions = false
		$.post '/arena', { enemy_id: enemy_id, background: background, map_id: map_id, versus: 'enemy' }, (response) ->
			if response.success is true
				Turbolinks.visit('arena/battle')
			else
				alert response.message
			end
		, 'json'

	duel: (origin_id, versus_id) ->

	npc: (npc_id) ->
		console.log "area do npc #{npc_id}"

	remove_npc: (npc_id) ->
		console.log "saiu da area do npc #{npc_id}"

	area: (area_id) ->
		this.areaOnChange = true

		return this.execMap(window.tickers.maps['map_'+area_id]) if window.tickers.maps['map_'+area_id]

		$.getJSON '/navigator/tickers', { ticker: 'map', map_id: area_id }, (map) ->
			window.tickers.maps['map_'+map.id] = map
			window.tickers.execMap(map)

	execMap: (map) ->
		ticker = $('<div />')
		ticker.addClass('ticker area').css('display', 'none').attr('id', "map_area_#{map.id}")
		# create
		close = $('<div />').addClass('close').text('X')
		title = $('<h3 />').text('Mudar de área?')
		content = $('<p />').text(map.name)
		link = $('<a />').attr('href', '#').attr('onclick', "window.tickers.changeArea('#{map.id}');").text('Ir para a área (pressione enter)')

		# append
		ticker.append close
		ticker.append title
		ticker.append content
		ticker.append link

		$("#tickers").prepend ticker
		ticker.slideDown 200

	remove_area: (area_id) ->
		this.areaOnChange = false
		$('#map_area_'+area_id).slideUp 200, ->
			$(this).remove()

	changeArea: (area_id) ->
		me.state.pause()
		$.post '/navigator/change_map', { map_id: area_id }, (response) ->
			#Turbolinks.visit('/navigator')
			window.location.href = '/navigator'
		, 'json'

	story: (story_id) ->


window.tickers = new Tickers()
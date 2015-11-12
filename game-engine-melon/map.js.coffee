# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://coffeescript.org/

window.game = {

	data: { steps: 0 }
	players: { }
	mainPlayer: { }
	mainPlayerData: { }
	socketData: { }
	currentMap: false
	updateMapPositions: false
	lastMapPositions: { x: 0, y: 0 }
	encounterRate: 4
	updateMapInterval: false
	gameReady: ->

	onload: ->
		if !me.video.init("map", 720, 400, { scaleMethod: 'fill-max' })
			alert "O seu browser não suporta HTML5 canvas."
			return

		me.audio.init "mp3,ogg"
		me.sys.pauseOnBlur = false;
		me.sys.fps = 30

		me.loader.onload = this.loaded.bind(this)

		me.loader.preload this.resources

		me.state.change me.state.LOADING

	loaded: ->
		#me.state.set me.state.MENU, new this.game.TitleScreen()
		me.state.set me.state.PLAY, new this.PlayScreen()

		me.pool.register "mainPlayer", window.game.PlayerEntity
		me.pool.register "enemyPlayer", window.game.NetworkPlayerEntity

		# keyboard
		me.input.bindKey me.input.KEY.LEFT, "left"
		me.input.bindKey me.input.KEY.RIGHT, "right"
		me.input.bindKey me.input.KEY.UP, "up"
		me.input.bindKey me.input.KEY.DOWN, "down"
		me.input.bindKey me.input.KEY.ENTER, "enter"

		# map updatable
		window.game.updateMapInterval = setInterval ->
			if window.game.updateMapPositions and !window.tickers.areaOnChange
				$.post '/users/update_map', window.game.updateMapPositions
				window.game.updateMapPositions = false
		, 30000 # a cada 30 segundos registrar a posição do mapa

		# start
		window.game.gameReady()
		me.state.change me.state.PLAY

	init: ->
		this.loadPlayScreen()
		this.initChat();

	loadPlayScreen: ->
		window.game.PlayScreen = me.ScreenObject.extend {
			onResetEvent: ->
				me.levelDirector.loadLevel("mundo")

				window.game.data.steps = 0

				#this.HUD = new window.game.HUD.Container()
				#me.game.world.addChild(this.HUD)
				window.game.loadMainPlayer window.game.mainPlayerData
				window.socket.emit 'gameReady', window.game.mainPlayerData

			onDestroyEvent: ->
				#me.game.world.removeChild this.HUD
		}

	updatePlayerState: (data) ->
		player = window.game.players[data.id]
		if player
			player.pos.x = data.pos.x
			player.pos.y = data.pos.y
			player.state = data.state
			player.direction = data.pos.direction

	removeEnemy: (data) ->
		enemy = this.players[data.id]
		if enemy
			me.game.world.removeChild(enemy)
			delete this.players[data.id]

	addEnemy: (data) ->
		if !data || window.game.players[data.id]
			return

		if data.map_id != window.game.currentMap
			return

		enemy = me.pool.pull 'enemyPlayer', data.pos.x, data.pos.y, {
			image: data.user.actor[0]+'_'+data.user.actor[1]
			spritewidth: 32
			spriteheight: 32
			width: 32
			height: 32
			id: data.id
			actor: data.user.actor
			direction: data.pos.direction
			name: data.name
			username: data.username
		}

		window.game.players[data.id] = enemy
		me.game.world.addChild enemy, 7 #data.z
		me.game.world.sort()

	loadMainPlayer: (data) ->
		params = {
			image: data.user.actor[0]+'_'+data.user.actor[1]
			spritewidth: 32
			spriteheight: 32
			width: 32
			height: 32
			id: data.id
			actor: data.user.actor
			direction: data.pos.direction
			name: data.name
			username: data.username
		}
		window.game.mainPlayer = me.pool.pull('mainPlayer', data.pos.x, data.pos.y, params)

		window.game.players[data.id] = window.game.mainPlayer;
		me.game.world.addChild window.game.mainPlayer, 8 #data.z

	command: (command) ->
		# remove slash
		command_full 		= command.substr 1
		command_slices 	= command_full.split ' '
		command 				= command_slices.shift()
		# available commands
		commands = {
			"help": ->
				msg = "Os seguintes comandos estão disponíveis: <br />"
				msg += "<b>/help </b>abre o menu de ajuda<br />"
				msg += "<b>/online </b>informa os nomes dos jogadores online incluindo você<br />"
				msg += "<b>/clear </b>limpa o histórico do chat<br />"
				msg += "<b>/enemies </b>exibe os inimigos que você pode encontrar no mapa<br />"
				msg += "<b>/about </b>monstra uma explicação do mapa se houver uma<br />"

				window.game.appendMessage msg

			"online": ->
				#
				players = []
				for id, player of window.game.players
					pdata = "<a href='/user/#{player.username}'>#{player.name}</a>"
					pdata += " (você)" if player.id == window.game.mainPlayerData.id
					players.push pdata

				msg = "<b>Jogadores online -> </b>"+players.join(', ')
				window.game.appendMessage msg

			"clear": ->
				#
				$('#all_messages').html ''
				window.game.appendMessage('Para mais informações rode o comando: /help')

			"enemies": ->
				#
				if !window.game.enemies
					msg = "Este mapa não possui inimigos."
				else
					msg = "<b>Inimigos -> </b>"+window.game.enemies

				window.game.appendMessage msg

			"about": ->
				#
				if !window.game.about
					msg = "Este mapa não possui uma descrição específica."
				else
					msg = "<b>Sobre -> </b>"+window.game.about

				window.game.appendMessage msg

			"not_found": (command) ->
				#
				window.game.appendMessage "<b>ERRO -> </b>O comando '/#{command}' que você tentou não foi encontrado. Para mais informações rode o comando: /help"
		}

		if !commands[command]
			commands["not_found"](command)
		else
			commands[command]()

	appendMessage: (msg) ->
		message = $('<div />').addClass('message').html(msg)
		$('#all_messages').append(message);
		objDiv = document.getElementById('all_messages');
		objDiv.scrollTop = objDiv.scrollHeight;

	initChat: ->
		$(document).on 'keydown', '#new_message', (e) ->
			input = $(this)

			if e.which
				keyCode = e.which
			else
				if e.keyCode
					keyCode = e.keyCode
				else
					keyCode = e.charCode

			if keyCode == 13
				e.preventDefault()
				message = input.val()

				if message.substr(0, 1) == '/'
					window.game.command(message)
					input.val ''
					return

				if message.length > 0 and !window.tickers.areaOnChange
					window.socket.emit 'newMessage', message
					input.val ''

	prepareSocket: ->

		window.socket = io.connect window.game.socketData.hostname#, { port: window.game.socketData.port, transports: ["websocket"] }
		window.socket.on 'connection', (s) ->
			s.emit('room', window.game.socketData.map)

		window.socket.on 'playerId', (playerId) ->
			window.game.playerId = playerId

		window.socket.on 'addPlayer', (data) ->
			window.game.addEnemy data

		window.socket.on 'removePlayer', (id) ->
			window.game.removeEnemy { id: id }

		window.socket.on 'addPlayers', (players) ->
			for id, player of players
				if player.id != window.game.mainPlayerData.id
					window.game.addEnemy player

		window.socket.on 'updatePlayerState', (data) ->
			window.game.updatePlayerState data

		window.socket.on 'playersOnline', (qty) ->
			$('#online span').text(qty);

		window.socket.on 'newMessage', (msg) ->
			# ignore the main player from receiving the same message
			# if msg.id != window.game.mainPlayerData.id
			message = $('<div />').addClass('message')
			name = $('<b />').text(msg.name);
			time = $("<i />").text(msg.time);
			mess = $('<span />').text(msg.message);

			name.addClass 'self' if msg.id == window.game.mainPlayerData.id

			message.append(name)
			message.append(time);
			message.append(mess);

			# append new message
			$('#all_messages').append(message);

			# scroll to bottom
			objDiv = document.getElementById('all_messages');
			objDiv.scrollTop = objDiv.scrollHeight;
}
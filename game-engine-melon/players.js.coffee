# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://coffeescript.org/

window.game.NetworkPlayerEntity = me.CollectableEntity.extend({

	init: (x, y, settings) ->
		this.parent(x, y, settings);
		this.gravity = 0
		this.isCollidable = true
		this.collidable = true
		this.step = 0
		this.name = settings.name
		this.username = settings.username
		this.id = settings.id
		this.type = window.game.ENEMY_OBJECT
		this.accelForce = 4
		this.direction = settings.direction;
		this.font = new me.Font("Verdana", 10, "#fff", "center")

		# get right actor sheet
		bloco = parseInt(settings.actor[2]) - 1
		down_base = if bloco > 3 then ((bloco - 4) * 3) + 48 else bloco * 3
		left_base = down_base + 12
		right_base = left_base + 12
		up_base = right_base + 12

		this.animations = {
			run_down: [down_base, down_base+1, down_base+2, down_base+1],
			run_left: [left_base, left_base+1, left_base+2, left_base+1],
			run_right: [right_base, right_base+1, right_base+2, right_base+1],
			run_up: [up_base, up_base+1, up_base+2, up_base+1]
		}

		# walking
		this.renderable.addAnimation 'run-down', this.animations.run_down, 200
		this.renderable.addAnimation 'run-left', this.animations.run_left, 200
		this.renderable.addAnimation 'run-right', this.animations.run_right, 200
		this.renderable.addAnimation 'run-up', this.animations.run_up, 200

		this.state = {}
		this.lastAnimationUsed = 'run-'+this.direction # Needed to prevent animation timer to be resett.. wich seam to happen otherwise
		this.animationToUseThisFrame = 'run-'+this.direction # Needed to prevent animation timer to be resett.. wich seam to happen otherwise
		this.renderable.setCurrentAnimation this.animationToUseThisFrame

	draw: (context) ->
		self = this
		this.font.draw context, self.username, self.pos.x + 15, self.pos.y - 20
		this.parent context

	update: (dt) ->
		this.vel.x 	= 0
		this.vel.y 	= 0

		return false if !Object.keys(this.state).length

		this.animationToUseThisFrame = 'run-left' if this.state['left']
		this.animationToUseThisFrame = 'run-right' if this.state['right']
		this.animationToUseThisFrame = 'run-up' if this.state['up']
		this.animationToUseThisFrame = 'run-down' if this.state['down']

		if this.animationToUseThisFrame != this.lastAnimationUsed
			this.lastAnimationUsed = this.animationToUseThisFrame
			this.renderable.setCurrentAnimation this.animationToUseThisFrame

		this.parent(dt)
		return true

})

window.game.PlayerEntity = me.ObjectEntity.extend({

	init: (x, y, settings) ->

		settings.collidable = true;

		this.parent(x, y, settings);

		#this.parent(new me.Rect(7, 10, 32, 32))
		this.addShape new me.Rect(new me.Vector2d(7,7), settings.width-10, settings.height-7)
		this.gravity = 0;
		this.name = settings.name;
		this.username = settings.username;
		this.id = settings.id
		this.step = 0;
		this.type = window.game.MAIN_PLAYER_OBJECT
		this.isCollidable = true
		this.font = new me.Font("Verdana", 11, "#b7e5ff", "center");
		this.state = {
			up: false
			down: false
			right: false
			left: false
		}
		this.direction = settings.direction;
		this.stateChanged = false;
		this.lastAnimationUsed = 'run-'+this.direction;
		this.animationToUseThisFrame = 'run-'+this.direction;
		this.accelForce = 4;

		# name
		#this.name = new me.Font("Arial", 20, "white", "left")

		# get right actor sheet
		bloco = parseInt(settings.actor[2]) - 1
		down_base = if bloco > 3 then ((bloco - 4) * 3) + 48 else bloco * 3
		left_base = down_base + 12
		right_base = left_base + 12
		up_base = right_base + 12

		this.animations = {
			run_down: [down_base, down_base+1, down_base+2, down_base+1],
			run_left: [left_base, left_base+1, left_base+2, left_base+1],
			run_right: [right_base, right_base+1, right_base+2, right_base+1],
			run_up: [up_base, up_base+1, up_base+2, up_base+1]
		}

		this.nextEncounterChance = 64 + Math.round( Math.random() * (255 - 64) + 1) * 4
		this.nextItemChance = 64 + Math.round( Math.random() * (255 - 64) + 1) * Math.round(2 + (Math.random() * 4 + 1))

		# walking
		this.renderable.addAnimation 'run-down', this.animations.run_down, 200
		this.renderable.addAnimation 'run-left', this.animations.run_left, 200
		this.renderable.addAnimation 'run-right', this.animations.run_right, 200
		this.renderable.addAnimation 'run-up', this.animations.run_up, 200

		this.renderable.setCurrentAnimation(this.animationToUseThisFrame)

		this.maxVel.x = this.maxVel.y = 25

		me.game.viewport.follow this.pos, me.game.viewport.AXIS.BOTH

		#this.body.updateBounds()

	draw: (context) ->
		self = this
		this.font.draw context, self.username, self.pos.x + 15, self.pos.y - 20
		this.parent context

	update: (dt) ->
		this.vel.x 	= 0
		this.vel.y 	= 0
		this.d_dt 	= dt / 20

		this.stateChanged 	= false;

		# limit player moves
		this.pos.y = me.game.currentLevel.height - 34 if this.pos.y > me.game.currentLevel.height - 34
		this.pos.x = me.game.currentLevel.width - 10 if this.pos.x > me.game.currentLevel.width - 10
		this.pos.x = 0 if this.pos.x < 0
		this.pos.y = 0 if this.pos.y < 0

		if me.input.isKeyPressed 'left'
			this.direction = 'left';
			this.animationToUseThisFrame = 'run-left';
			this.vel.x -= 1;
			this.state['left'] = true;
			this.stateChanged = true;
		else
			this.state['left'] = false;

		if me.input.isKeyPressed 'right'
			this.direction = 'right';
			this.animationToUseThisFrame = 'run-right'
			this.vel.x += 1;
			this.state['right'] = true;
			this.stateChanged = true;
		else
			this.state['right'] = false;

		if me.input.isKeyPressed 'up'
			this.direction = 'up';
			this.animationToUseThisFrame = 'run-up';
			this.vel.y -= 1;
			this.state['up'] = true;
			this.stateChanged = true;
		else
			this.state['up'] = false;

		if me.input.isKeyPressed 'down'
			this.direction = 'down';
			this.animationToUseThisFrame = 'run-down';
			this.vel.y += 1;
			this.state['down'] = true;
			this.stateChanged = true;
		else
			this.state['down'] = false;

		# if map is collided, we can press enter to jump on it
		if me.input.isKeyPressed 'enter'
			if this.map
				window.tickers.changeArea(this.map);

		if this.animationToUseThisFrame != this.lastAnimationUsed
			this.lastAnimationUsed = this.animationToUseThisFrame;
			this.renderable.setCurrentAnimation this.animationToUseThisFrame;

		# Now calc actual vel to prevent speeding by going diag
		this.vel.normalize()
		this.vel.scale this.accelForce * this.d_dt;

		this.updateMovement()
		#this._super(me.Entity, 'update', [dt]);

		res = me.game.world.collide(this);

		# map collision
		if res and res.type and (res.type.length > 0 and res.type.substr(0, 3) == "map")
			if !this.map
				this.map = res.type.split('_')[1]
				window.tickers.area(this.map)
		else
			if this.map
				window.tickers.remove_area(this.map)
				this.map = false

		# npc collision
		if res and res.type and (res.type.length > 0 and res.type.substr(0, 3) == "npc")
			if !this.npc
				this.npc = res.type.split('_')[1]
				window.tickers.npc(this.npc)
		else
			if this.npc
				window.tickers.remove_npc(this.npc)
				this.npc = false

		if this.stateChanged
			# Encounter Rate
			this.nextEncounterChance -= window.game.encounterRate
			this.nextItemChance -= window.game.encounterRate
			if this.nextEncounterChance < 0
				window.tickers.newBattle()
				this.nextEncounterChance = 64 + Math.round( Math.random() * (255 - 64) + 1) * 2
			if this.nextItemChance < 0
				window.tickers.newItem()
				this.nextItemChance = 64 + Math.round( Math.random() * (255 - 64) + 1) * Math.round(2 + (Math.random() * 4 + 1))
			#
			window.game.updateMapPositions = x: this.pos.x, y: this.pos.y, direction: this.direction
			window.game.lastMapPositions = window.game.updateMapPositions
			window.socket.emit 'updatePlayerState', { x: this.pos.x, y: this.pos.y, direction: this.direction }, this.state
			this.parent dt
			return true
		else
			return false

})
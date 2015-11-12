var util	= require("util"),
		io 		= require("socket.io");

// Socket.io: Setting up multiplayer
/* ----------------------------------------------------------------- */

var sessions = {};
var maps = {};
var players = {};

iosocket	= io.listen(1337);
iosocket.configure(function(){
	iosocket.set("transports", ["websocket"]);
	iosocket.set("log level", 2);
});

Object.size = function(obj) {
    var size = 0, key;
    for (key in obj) {
        if (obj.hasOwnProperty(key)) size++;
    }
    return size;
};

function strip_tags(input, allowed) {
  allowed = (((allowed || '') + '')
    .toLowerCase()
    .match(/<[a-z][a-z0-9]*>/g) || [])
    .join(''); // making sure the allowed arg is a string containing only tags in lowercase (<a><b><c>)
  var tags = /<\/?([a-z][a-z0-9]*)\b[^>]*>/gi,
    commentsAndPhpTags = /<!--[\s\S]*?-->|<\?(?:php)?[\s\S]*?\?>/gi;
  return input.replace(commentsAndPhpTags, '')
    .replace(tags, function($0, $1) {
      return allowed.indexOf('<' + $1.toLowerCase() + '>') > -1 ? $0 : '';
    });
}

function addToMap(sess, map_id) {
  sessions[sess] = map_id;
}

function getMap(sess) {
  return sessions[sess];
}

function getMapObject(map_id) {
  return maps[map_id];
}

function getPlayer(sess) {
  map_id = sessions[sess];
  return !map_id ? false : maps[map_id].players[sess]
}

function allPlayers(map_id) {
  return maps[map_id].players;
}

function addPlayer(sess, data) {
  map_id = sessions[sess];

  if(!maps[map_id]) {
    maps[map_id] = { players: {} };
  }

  maps[map_id].players[sess] = data;
}

function removePlayer(sess) {
  map_id = sessions[sess];
  delete sessions[sess];
  delete maps[map_id].players[sess]
}

// Socket.io: Setting up event handlers for all the messages that come
// in from the client (check out /public/js/game.js and /views/game.jade 
// for that).

iosocket.sockets.on('connection', function(socket) {
	util.log("New player has connected: "+socket.id);

	socket.on('room', function(room) {
		util.log("Joining room: "+room);
		socket.join(room);
	})

  socket.on('disconnect', function () {
  	if(p = getPlayer(socket.sessionId)) {
      removePlayer(socket.sessionId);
  		util.log("disconnect session "+socket.sessionId+" for room map-"+p.map_id)
      util.log("Remain players on map-"+p.map_id+": "+Object.size(getMapObject(p.map_id).players))
    	socket.broadcast.in('map-'+p.map_id).emit('removePlayer', p.id);
      iosocket.sockets.in('map-'+p.map_id).emit('playersOnline', Object.size(getMapObject(p.map_id).players));
    } else {
    	util.log("disconnect session "+socket.sessionId+" for any room");
    	socket.broadcast.emit('removePlayer', socket.uniqueId);
      delete sessions[socket.sessionId]
    }
  });

  socket.on('gameReady', function(data) {
    // create map with players
    if(!maps[data.map_id] || !maps[data.map_id].players) {
      maps[data.map_id] = {};
      maps[data.map_id].players = {};
    }

    // define ids
    socket.sessionId = "player_"+data.id;
    socket.uniqueId = data.id;
    socket.playerName = data.name;

    // if exists, remove
    if(getPlayer(socket.sessionId)) {
      socket.broadcast.in('map-'+data.map_id).emit('removePlayer', getPlayer(socket.sessionId).id);
      removePlayer(socket.sessionId);
    }

    // add players
    var player = data;
    addToMap(socket.sessionId, data.map_id);
    addPlayer(socket.sessionId, player);

    // socket messages
    socket.broadcast.in('map-'+player.map_id).emit('addPlayer', player);
    socket.in('map-'+player.map_id).emit('playerId', player.id);
    socket.in('map-'+player.map_id).emit('addPlayers', allPlayers(player.map_id));
    iosocket.sockets.in('map-'+player.map_id).emit('playersOnline', Object.size(getMapObject(player.map_id).players));

    // logs
    //util.log("new player ("+socket.sessionId+") entered at map "+player.map_id)
    //util.log("Players online this map: "+Object.size(getMapObject(data.map_id).players));
    //util.log("Total players online: "+Object.size(sessions));
  });

  socket.on('newMessage', function(message){
    player  = getPlayer(socket.sessionId);
    date    = new Date();
    hour    = date.getHours();
    minute  = date.getMinutes();
    msg = {
      name: player.name,
      id: player.id,
      message: strip_tags(message),
      time: '('+( hour < 10 ? "0" + hour : hour ) + ':' + ( minute < 10 ? "0" + minute : minute )+')'
    }
    //
    iosocket.sockets.in('map-'+player.map_id).emit('newMessage', msg);
  })

  socket.on('updatePlayerState', function(position, state) {
    if(!getPlayer(socket.sessionId)) {
      return;
    }

    player = getPlayer(socket.sessionId)
    player.pos = position;
    player.direction = position.direction;

    socket.broadcast.in('map-'+player.map_id).emit('updatePlayerState', { id: player.id, pos: position, state: state });
  });

});
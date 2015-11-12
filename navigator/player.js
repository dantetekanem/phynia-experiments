var Player 	= function(startX, startY, startId, startDirection)
{
	var x 				= startX,
			y 				= startY,
			direction = startDirection,
			id 				= startId;

	var getX = function()
	{
		return x;
	}

	var getY = function()
	{
		return y;
	}

	var getDirection = function()
	{
		return direction;
	}

	var getMapId = function()
	{
		return map_id;
	}

	var setX = function(newX)
	{
		x = newX;
	}

	var setY = function(newY)
	{
		y = newY;
	}

	var setDirection = function(newDirection)
	{
		direction = newDirection;
	}

	return {
		mapId: getMapId,
		direction: getDirection,
		getX: getX,
		getY: getY,
		setX: setX,
		setY: setY,
		setDirection: setDirection,
		id: id
	}
};

exports.Player = Player;
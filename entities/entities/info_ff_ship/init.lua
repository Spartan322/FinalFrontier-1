ENT.Type = "point"
ENT.Base = "base_point"

ENT.BaseHullHealth = 1
ENT.Rooms = nil
ENT._roomlist = nil
ENT.Doors = nil

ENT.Bounds = nil

function ENT:KeyValue( key, value )
	if key == "hullhealth" then
		self.BaseHullHealth = tonumber( value )
	end
end

function ENT:Initialize()
	self.Rooms = {}
	self._roomlist = {}
	self.Doors = {}
	self.Bounds = Bounds()
end

function ENT:InitPostEntity()
	ships.Add( self )
end

function ENT:AddRoom( room )
	local name = room:GetName()
	if not name then return end

	self.Rooms[ name ] = room
	table.insert( self._roomlist, room )
	self.Bounds:AddBounds( room.Bounds )
	
	room.Index = #self._roomlist
end

function ENT:AddDoor( door )
	if not table.HasValue( self.Doors, door ) then
		table.insert( self.Doors, door )
	end
end

util.AddNetworkString( "InitShipData" )
util.AddNetworkString( "ShipRoomStates" )

function ENT:SendInitShipData( ply )
	net.Start( "InitShipData" )
		net.WriteString( self:GetName() )		
		net.WriteInt( table.Count( self.Rooms ), 8 )
		
		local doors = {}
		
		for name, room in pairs( self.Rooms ) do
		
			net.WriteString( name )
			net.WriteInt( room.Index, 8 )
			if room.System then
				net.WriteString( room.System.Name )
			else
				net.WriteString( "" )
			end
			net.WriteInt( table.Count( room.Corners ), 8 )
			for i, v in pairs( room.Corners ) do
				net.WriteInt( i, 8 )
				net.WriteFloat( v.x )
				net.WriteFloat( v.y )
			end
			
			for _, door in ipairs( room.Doors ) do
				if not table.HasValue( doors, door ) then
					table.insert( doors, door )
				end
			end
		end
		
		net.WriteInt( #doors, 8 )
		for _, door in ipairs( doors ) do
			local pos = door:GetPos()
			net.WriteFloat( pos.x )
			net.WriteFloat( pos.y )
			net.WriteFloat( door:GetAngles().y )		
			net.WriteInt( door.Rooms[ 1 ].Index, 8 )
			net.WriteInt( door.Rooms[ 2 ].Index, 8 )
		end
	net.Send( ply )
end

local function IsDifferent( valA, valB, err )
	err = err or 0.01
	local diff = math.abs( ( valA - valB ) / valA )
	return diff > err
end

function ENT:SendShipRoomStates( ply )
	local name = self:GetName()

	ply.RoomStateCache = ply.RoomStateCache or {}
	ply.RoomStateCache[ name ] = ply.RoomStateCache[ name ] or {}
	
	local shipCache = ply.RoomStateCache[ name ]

	net.Start( "ShipRoomStates" )
		net.WriteFloat( CurTime() )
		net.WriteString( self:GetName() )
		for index, room in ipairs( self._roomlist ) do
			shipCache[ index ] = shipCache[ index ] or { temp = 0, atmo = 0, shld = 0 }
			local cache = shipCache[ index ]
			local temp = room:GetTemperature()
			local atmo = room:GetAtmosphere()
			local shld = room:GetShields()
			
			if IsDifferent( cache.temp, temp ) or
				IsDifferent( cache.atmo, atmo ) or
				IsDifferent( cache.shld, shld ) then
				
				net.WriteInt( index, 8 )
				net.WriteFloat( room:GetTemperature() )
				net.WriteFloat( room:GetAtmosphere() )
				net.WriteFloat( room:GetShields() )
				
				cache.temp = temp
				cache.atmo = atmo
				cache.shld = shld
			end
		end
		net.WriteInt( 0, 8 )
	net.Send( ply )
end

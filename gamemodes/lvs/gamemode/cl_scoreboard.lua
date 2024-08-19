local ColorA = Color(0,0,0,75)
local ColorB = Color(0,0,0,150)

local function CalcTeamSwap()
	local MyTeam = LocalPlayer():lvsGetAITeam()

	local Left = 1

	if MyTeam == 1 or MyTeam == 2 then
		Left = MyTeam
	end

	local Right = 2
	if Left == 2 then
		Right = 1
	end

	return Left, Right
end

local function CreatePlayerLine( ply, Parent, AlternateColor )
	local plyPanel = Parent:Add( "DPanel" )
	plyPanel.Player = ply
	plyPanel:Dock( TOP )
	plyPanel:DockMargin( 0, 0, 0, 1 )
	plyPanel:SetHeight( 32 )
	plyPanel.PaintColor = AlternateColor and ColorA or ColorB
	plyPanel.Paint = function(self, w, h )
		surface.SetDrawColor( self.PaintColor )
		surface.DrawRect(0, 0, w, h)
	end
	plyPanel.Think = function( self )
		if not IsValid( self.Player ) then
			self:Clear()
			self:Remove()

			return
		end

		if self.PName == nil or self.PName ~= self.Player:Nick() then
			self.PName = self.Player:Nick()

			self.Name:SetText( self.PName )
		end

		if self.NumKills == nil or self.NumKills ~= self.Player:Frags() then
			self.NumKills = self.Player:Frags()

			self.Kills:SetText( self.NumKills )
		end

		if self.NumDeaths == nil or self.NumDeaths ~= self.Player:Deaths() then
			self.NumDeaths = self.Player:Deaths()

			self.Deaths:SetText( self.NumDeaths )
		end

		if self.NumPing == nil or self.NumPing ~= self.Player:Ping() then
			self.NumPing = self.Player:Ping()
			self.Ping:SetText( self.NumPing )
		end
	end

	plyPanel.AvatarButton = plyPanel:Add( "DButton" )
	plyPanel.AvatarButton:Dock( LEFT )
	plyPanel.AvatarButton:SetSize( 32, 32 )
	plyPanel.AvatarButton.DoClick = function() plyPanel.Player:ShowProfile() end

	plyPanel.Avatar = vgui.Create( "AvatarImage", plyPanel.AvatarButton )
	plyPanel.Avatar:SetSize( 32, 32 )
	plyPanel.Avatar:SetMouseInputEnabled( false )
	plyPanel.Avatar:SetPlayer( ply, 64 )

	plyPanel.Name = plyPanel:Add( "DLabel" )
	plyPanel.Name:Dock( FILL )
	plyPanel.Name:SetFont( "ScoreboardDefault" )
	plyPanel.Name:SetTextColor( color_white )
	plyPanel.Name:DockMargin( 8, 0, 0, 0 )

	plyPanel.Mute = plyPanel:Add( "DImageButton" )
	plyPanel.Mute:SetSize( 32, 32 )
	plyPanel.Mute:Dock( RIGHT )
	plyPanel.Mute.Think = function( self )
		if not IsValid( self.Player ) then return end

		if self.Muted == nil or self.Muted ~= plyPanel.Player:IsMuted() then
			self.Muted = plyPanel.Player:IsMuted()

			if self.Muted then
				self:SetImage( "icon32/muted.png" )
			else
				self:SetImage( "icon32/unmuted.png" )
			end
		end
	end
	plyPanel.Mute.DoClick = function( self )
		plyPanel.Player:SetMuted( not self.Muted )
	end

	plyPanel.Ping = plyPanel:Add( "DLabel" )
	plyPanel.Ping:Dock( RIGHT )
	plyPanel.Ping:SetWidth( 50 )
	plyPanel.Ping:SetFont( "ScoreboardDefault" )
	plyPanel.Ping:SetTextColor( color_white )
	plyPanel.Ping:SetContentAlignment( 5 )

	plyPanel.Deaths = plyPanel:Add( "DLabel" )
	plyPanel.Deaths:Dock( RIGHT )
	plyPanel.Deaths:SetWidth( 50 )
	plyPanel.Deaths:SetFont( "ScoreboardDefault" )
	plyPanel.Deaths:SetTextColor( color_white )
	plyPanel.Deaths:SetContentAlignment( 5 )

	plyPanel.Kills = plyPanel:Add( "DLabel" )
	plyPanel.Kills:Dock( RIGHT )
	plyPanel.Kills:SetWidth( 50 )
	plyPanel.Kills:SetFont( "ScoreboardDefault" )
	plyPanel.Kills:SetTextColor( color_white )
	plyPanel.Kills:SetContentAlignment( 5 )
end

local ColFriend = GM.ColorFriend
local ColEnemy = GM.ColorEnemy

local blur = Material("pp/blurscreen")
local header = Material("lvs/tournament/header.png")
function GM:ScoreboardShow()
	local ply = LocalPlayer()

	if IsValid( self.ScoreBoard ) then
		self.ScoreBoard:Remove()
	end

	local LeftTeam, RightTeam = CalcTeamSwap()

	local X = ScrW()
	local Y = ScrH()

	local Canvas = vgui.Create("DPanel")
	Canvas:SetPos( 0, 0 )
	Canvas:SetSize( X, Y )
	Canvas:SetPaintBackground( false )

	self.ScoreBoard = Canvas

	local TopBar = vgui.Create("DPanel", Canvas )
	TopBar:SetSize( 1, 25 )
	TopBar:Dock( TOP )
	TopBar:SetPaintBackground( false )

	local PaddingW = 150
	local PaddingH = 75

	local MainCanvas = vgui.Create("DPanel", Canvas )
	MainCanvas:Dock( FILL )
	MainCanvas:DockPadding( PaddingW, PaddingH, PaddingW, PaddingH )
	MainCanvas.Paint = function(self, w, h )
		draw.RoundedBox( 10, X * 0.5 - 330, Y - 85, 660, 40, Color( 0, 0, 0, 200 ) )
	end

	local VolumeCrowd = vgui.Create( "DNumSlider", Canvas )
	VolumeCrowd:SetPos( X * 0.5 - 300, Y - 65 )
	VolumeCrowd:SetSize( 300, 50 )
	VolumeCrowd:SetText( "Crowd Reaction Volume" )
	VolumeCrowd:SetMin( 0 )
	VolumeCrowd:SetMax( 1 )	
	VolumeCrowd:SetDecimals( 2 )
	VolumeCrowd:SetConVar( "lvs_volume_crowd" )

	local VolumeMusic = vgui.Create( "DNumSlider", Canvas )
	VolumeMusic:SetPos( X * 0.5 + 30, Y - 65 )
	VolumeMusic:SetSize( 300, 50 )
	VolumeMusic:SetText( "Music Volume" )
	VolumeMusic:SetMin( 0 )
	VolumeMusic:SetMax( 1 )	
	VolumeMusic:SetDecimals( 2 )
	VolumeMusic:SetConVar( "lvs_volume_music" )

	local CenterMenu = vgui.Create("DPanel", MainCanvas )
	CenterMenu:Dock( FILL )
	CenterMenu:DockPadding( 0, 0, 0, 0 )
	CenterMenu.Paint = function(self, w, h )
		surface.SetMaterial( blur )

		blur:SetFloat( "$blur", 5 )
		blur:Recompute()

		if render then render.UpdateScreenEffectTexture() end

		surface.SetDrawColor( 255, 255, 255, 255 )

		local offsetX, offsetY = self:GetPos()

		surface.DrawTexturedRect( -offsetX, -offsetY - (PaddingH - 25) * 0.5, ScrW(), ScrH() )
	end

	local CenterTOP = CenterMenu:Add( "DLabel" )
	CenterTOP:SetFont( "ScoreboardDefaultTitle" )
	CenterTOP:SetText( GetHostName() )
	CenterTOP:SetTextColor( color_white )
	CenterTOP:Dock( TOP )
	CenterTOP:SetHeight( 100 )
	CenterTOP:SetContentAlignment( 5 )
	CenterTOP.Paint = function(self, w, h )
		surface.SetDrawColor( Color( 0, 0, 0, 100 ) )
		surface.DrawRect(0, 0, w, h)

		surface.SetDrawColor( color_white )
		surface.SetMaterial( header )
		surface.DrawTexturedRect( 1, 1, 288, 98 )
	end

	local CenterRIGHT = vgui.Create("DPanel", CenterMenu )
	CenterRIGHT:SetWide( X * 0.5 - 150 )
	CenterRIGHT:Dock( RIGHT )
	CenterRIGHT.Paint = function(self, w, h )
		surface.SetDrawColor( Color( 0, 0, 0, 50 ) )
		surface.DrawRect(0, 0, w, h)

		surface.SetDrawColor( Color( ColEnemy.r, ColEnemy.g, ColEnemy.b, 50 ) )
		surface.DrawRect(32, 0, 75, h)

		draw.SimpleText( "Team "..RightTeam, "ScoreboardDefault", 70, 20, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )
	end

	local CenterLEFT = vgui.Create("DPanel", CenterMenu )
	CenterLEFT:SetWide( X * 0.5 - 150 )
	CenterLEFT:Dock( LEFT )
	CenterLEFT.Paint = function(self, w, h )
		surface.SetDrawColor( Color( 0, 0, 0, 50 ) )
		surface.DrawRect(0, 0, w, h)

		surface.SetDrawColor( Color( ColFriend.r, ColFriend.g, ColFriend.b, 50 ) )
		surface.DrawRect(32, 0, 75, h)

		draw.SimpleText( "Team "..LeftTeam, "ScoreboardDefault", 70, 20, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )
	end

	local ScrollLEFT = vgui.Create( "DScrollPanel", CenterLEFT )
	ScrollLEFT:DockMargin( 140, 25, 25, 0 )
	ScrollLEFT:Dock( FILL )

	local ScrollRIGHT = vgui.Create( "DScrollPanel", CenterRIGHT )
	ScrollRIGHT:DockMargin( 140, 25, 25, 0 )
	ScrollRIGHT:Dock( FILL )

	local Alternate = false

	local Left = LeftTeam == 1 and ScrollLEFT or ScrollRIGHT
	local Right = RightTeam == 1 and ScrollLEFT or ScrollRIGHT

	for _, ply in pairs( self:GameGetPlayersTeam1() ) do

		CreatePlayerLine( ply, Left, Alternate )

		Alternate = not Alternate
	end

	for _, ply in pairs( self:GameGetPlayersTeam2() ) do

		CreatePlayerLine( ply, Right, Alternate )

		Alternate = not Alternate
	end

	gui.EnableScreenClicker( true )
end

function GM:ScoreboardHide()
	gui.EnableScreenClicker( false )

	if IsValid( self.ScoreBoard ) then
		self.ScoreBoard:Remove()
	end
end

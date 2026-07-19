using { /Fortnite.com/Devices }
using { /Verse.org/Simulation }
using { /Verse.org/Random }
using { /UnrealEngine.com/Temporary/SpatialMath }

japanese_casino_tower := class(creative_device):

    @editable
    FloorTileAsset : creative_prop_asset = DefaultCreativePropAsset
    @editable
    WallAsset : creative_prop_asset = DefaultCreativePropAsset
    @editable
    PillarAsset : creative_prop_asset = DefaultCreativePropAsset
    @editable
    EaveAsset : creative_prop_asset = DefaultCreativePropAsset
    @editable
    LanternAsset : creative_prop_asset = DefaultCreativePropAsset
    @editable
    DecorAsset : creative_prop_asset = DefaultCreativePropAsset
    @editable
    HelipadAsset : creative_prop_asset = DefaultCreativePropAsset

    @editable
    NumberOfFloors : int = 10

    @editable
    FloorHeight : float = 500.0

    @editable
    BaseWidth : float = 3600.0

    @editable
    TierShrink : float = 120.0

    @editable
    FloorTileSize : float = 512.0

    @editable
    WallPieceWidth : float = 512.0

    @editable
    EaveOverhang : float = 260.0

    @editable
    DecorPerFloor : int = 10

    @editable
    BuildOnGameStart : logic = false

    var SpawnedProps : []creative_prop = array{}

    RingDirections : []vector3 = array:
        vector3{ X := 1.0,  Y := 0.0,  Z := 0.0 }
        vector3{ X := 0.7,  Y := 0.7,  Z := 0.0 }
        vector3{ X := 0.0,  Y := 1.0,  Z := 0.0 }
        vector3{ X := -0.7, Y := 0.7,  Z := 0.0 }
        vector3{ X := -1.0, Y := 0.0,  Z := 0.0 }
        vector3{ X := -0.7, Y := -0.7, Z := 0.0 }
        vector3{ X := 0.0,  Y := -1.0, Z := 0.0 }
        vector3{ X := 0.7,  Y := -0.7, Z := 0.0 }

    OnBegin<override>()<suspends> : void =
        if (BuildOnGameStart?):
            BuildNow()

    BuildNow() : void =
        Base := GetTransform().Translation

        for (FloorIndex := 0..NumberOfFloors - 1):
            BuildStory(Base, FloorIndex)

        BuildRoof(Base)
        BuildEntranceGate(Base)
        Print("Japanese casino tower built.")

    GetFloorArrivalPosition(FloorIndex : int) : vector3 =
        Base := GetTransform().Translation
        return vector3:
            X := Base.X
            Y := Base.Y - (FloorWidthAt(FloorIndex) / 2.0) + 400.0
            Z := Base.Z + (FloorHeight * (FloorIndex * 1.0)) + 300.0

    Demolish() : void =
        for (Prop : SpawnedProps):
            if (Prop.IsValid[]):
                Prop.Dispose()
        set SpawnedProps = array{}

    FloorWidthAt(FloorIndex : int) : float =
        BaseWidth - (TierShrink * (FloorIndex * 1.0))

    BuildStory(Base : vector3, FloorIndex : int) : void =
        Width := FloorWidthAt(FloorIndex)
        FloorZ := Base.Z + (FloorHeight * (FloorIndex * 1.0))

        SpawnFloorSlab(Base, FloorZ, Width)
        SpawnWalls(Base, FloorZ, Width, FloorIndex)
        SpawnCornerPillars(Base, FloorZ, Width)
        SpawnEaveRing(Base, FloorZ + FloorHeight, Width)
        SpawnLanternRow(Base, FloorZ, Width)
        SpawnInterior(Base, FloorZ, Width)

    SpawnFloorSlab(Base : vector3, Z : float, Width : float) : void =
        Half := Width / 2.0
        var OffsetY : float = -Half + (FloorTileSize / 2.0)
        loop:
            if (OffsetY > Half):
                break
            var OffsetX : float = -Half + (FloorTileSize / 2.0)
            loop:
                if (OffsetX > Half):
                    break
                Pos := vector3{ X := Base.X + OffsetX, Y := Base.Y + OffsetY, Z := Z }
                SpawnIt(FloorTileAsset, Pos, YawRot(0.0))
                set OffsetX += FloorTileSize
            set OffsetY += FloorTileSize

    SpawnWalls(Base : vector3, Z : float, Width : float, FloorIndex : int) : void =
        Half := Width / 2.0
        WallZ := Z + (FloorHeight / 2.0)
        DoorHalfWidth := WallPieceWidth

        var Along : float = -Half + (WallPieceWidth / 2.0)
        loop:
            if (Along > Half):
                break

            var IsDoorway : logic = false
            if (FloorIndex = 0, Along < DoorHalfWidth, Along > -DoorHalfWidth):
                set IsDoorway = true
            if (IsDoorway = false):
                FrontPos := vector3{ X := Base.X + Along, Y := Base.Y - Half, Z := WallZ }
                SpawnIt(WallAsset, FrontPos, YawRot(0.0))

            BackPos := vector3{ X := Base.X + Along, Y := Base.Y + Half, Z := WallZ }
            SpawnIt(WallAsset, BackPos, YawRot(0.0))

            EastPos := vector3{ X := Base.X + Half, Y := Base.Y + Along, Z := WallZ }
            SpawnIt(WallAsset, EastPos, YawRot(90.0))

            WestPos := vector3{ X := Base.X - Half, Y := Base.Y + Along, Z := WallZ }
            SpawnIt(WallAsset, WestPos, YawRot(90.0))

            set Along += WallPieceWidth

    SpawnCornerPillars(Base : vector3, Z : float, Width : float) : void =
        Half := Width / 2.0
        PZ := Z + (FloorHeight / 2.0)
        Corners : []vector3 = array:
            vector3{ X := Base.X + Half, Y := Base.Y + Half, Z := PZ }
            vector3{ X := Base.X - Half, Y := Base.Y + Half, Z := PZ }
            vector3{ X := Base.X + Half, Y := Base.Y - Half, Z := PZ }
            vector3{ X := Base.X - Half, Y := Base.Y - Half, Z := PZ }
        for (Corner : Corners):
            SpawnIt(PillarAsset, Corner, YawRot(0.0))

    SpawnEaveRing(Base : vector3, TopZ : float, Width : float) : void =
        Half := (Width / 2.0) + EaveOverhang
        Pieces := 6
        Seg := (Width + (EaveOverhang * 2.0)) / (Pieces * 1.0)
        EaveZ := TopZ - 40.0
        Tilt := -14.0

        for (Index := 0..Pieces - 1):
            Along := -Half + (Seg / 2.0) + (Seg * (Index * 1.0))

            SpawnIt(EaveAsset, vector3{ X := Base.X + Along, Y := Base.Y - Half, Z := EaveZ }, PitchYawRot(0.0, Tilt))
            SpawnIt(EaveAsset, vector3{ X := Base.X + Along, Y := Base.Y + Half, Z := EaveZ }, PitchYawRot(180.0, Tilt))
            SpawnIt(EaveAsset, vector3{ X := Base.X + Half, Y := Base.Y + Along, Z := EaveZ }, PitchYawRot(90.0, Tilt))
            SpawnIt(EaveAsset, vector3{ X := Base.X - Half, Y := Base.Y + Along, Z := EaveZ }, PitchYawRot(270.0, Tilt))

    SpawnLanternRow(Base : vector3, Z : float, Width : float) : void =
        Half := Width / 2.0
        Count := 4
        Spacing := Width / ((Count + 1) * 1.0)
        LanternZ := Z + FloorHeight - 120.0
        for (Index := 1..Count):
            Pos := vector3:
                X := Base.X - Half + (Spacing * (Index * 1.0))
                Y := Base.Y - Half - 60.0
                Z := LanternZ
            SpawnIt(LanternAsset, Pos, YawRot(0.0))

    SpawnInterior(Base : vector3, Z : float, Width : float) : void =
        Half := (Width / 2.0) - 350.0
        PartZ := Z + (FloorHeight / 2.0)

        SpawnIt(WallAsset, vector3{ X := Base.X - (Width / 5.0), Y := Base.Y + (Width / 6.0), Z := PartZ }, YawRot(90.0))
        SpawnIt(WallAsset, vector3{ X := Base.X + (Width / 5.0), Y := Base.Y - (Width / 6.0), Z := PartZ }, YawRot(90.0))

        for (Index := 0..DecorPerFloor - 1):
            Pos := vector3:
                X := GetRandomFloat(Base.X - Half, Base.X + Half)
                Y := GetRandomFloat(Base.Y - Half, Base.Y + Half)
                Z := Z + 10.0
            SpawnIt(DecorAsset, Pos, YawRot(GetRandomFloat(0.0, 360.0)))

    BuildRoof(Base : vector3) : void =
        RoofZ := Base.Z + (FloorHeight * (NumberOfFloors * 1.0))
        RoofWidth := FloorWidthAt(NumberOfFloors - 1)

        SpawnFloorSlab(Base, RoofZ, RoofWidth)

        PadPos := vector3{ X := Base.X, Y := Base.Y, Z := RoofZ + 12.0 }
        SpawnIt(HelipadAsset, PadPos, YawRot(0.0))

        Radius := (RoofWidth / 2.0) - 220.0
        for (Direction : RingDirections):
            Pos := vector3:
                X := Base.X + (Direction.X * Radius)
                Y := Base.Y + (Direction.Y * Radius)
                Z := RoofZ + 20.0
            SpawnIt(LanternAsset, Pos, YawRot(0.0))

    BuildEntranceGate(Base : vector3) : void =
        Half := BaseWidth / 2.0
        GateY := Base.Y - Half - 350.0
        GateHalfWidth := 320.0

        SpawnIt(PillarAsset, vector3{ X := Base.X - GateHalfWidth, Y := GateY, Z := Base.Z + 250.0 }, YawRot(0.0))
        SpawnIt(PillarAsset, vector3{ X := Base.X + GateHalfWidth, Y := GateY, Z := Base.Z + 250.0 }, YawRot(0.0))
        SpawnIt(EaveAsset, vector3{ X := Base.X, Y := GateY, Z := Base.Z + 520.0 }, YawRot(90.0))
        SpawnIt(LanternAsset, vector3{ X := Base.X - GateHalfWidth, Y := GateY - 100.0, Z := Base.Z + 380.0 }, YawRot(0.0))
        SpawnIt(LanternAsset, vector3{ X := Base.X + GateHalfWidth, Y := GateY - 100.0, Z := Base.Z + 380.0 }, YawRot(0.0))

    YawRot(Degrees : float) : rotation =
        MakeRotationFromYawPitchRollDegrees(Degrees, 0.0, 0.0)

    PitchYawRot(Yaw : float, Pitch : float) : rotation =
        MakeRotationFromYawPitchRollDegrees(Yaw, Pitch, 0.0)

    SpawnIt(Asset : creative_prop_asset, Position : vector3, Rotation : rotation) : void =
        Result := SpawnProp(Asset, Position, Rotation)
        if (NewProp := Result(0)?):
            set SpawnedProps += array{NewProp}
# fill this file with your verse-script
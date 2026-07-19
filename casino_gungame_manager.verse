using { /Fortnite.com/Devices }
using { /Verse.org/Simulation }
using { /Verse.org/Random }
using { /Fortnite.com/Characters }
using { /Fortnite.com/Game }
using { /UnrealEngine.com/Temporary/SpatialMath }

StringToMessage<localizes>(Text : string) : message = "{Text}"

casino_gungame_manager := class(creative_device):

    @editable
    Tower : japanese_casino_tower = japanese_casino_tower{}

    @editable
    BuildTowerAtStart : logic = false

    @editable
    NormalSpawners : []guard_spawner_device = array{}

    @editable
    MeleeSpawners : []guard_spawner_device = array{}

    @editable
    FloorWeaponGranters : []item_granter_device = array{}

    @editable
    FloorWeaponNames : []string = array{}

    @editable
    HadesSpawner : npc_spawner_device = npc_spawner_device{}

    @editable
    BossAddsSpawner : guard_spawner_device = guard_spawner_device{}

    @editable
    VictoryDevice : end_game_device = end_game_device{}

    @editable
    FloorHUD : hud_message_device = hud_message_device{}

    @editable
    PlayerSpawnPads : []player_spawner_device = array{}

    @editable
    BaseEnemiesPerFloor : int = 14

    @editable
    EnemiesAddedPerFloor : int = 6

    @editable
    BaseSimultaneousEnemies : int = 4

    @editable
    MeleeGuardPercent : int = 50

    @editable
    IntermissionSeconds : float = 8.0

    var ElimCount : int = 0
    ElimSignal : event() = event(){}
    var HadesDown : logic = false
    var LastKiller : ?agent = false
    var CurrentFloorIndex : int = 0

    OnBegin<override>()<suspends> : void =
        if (BuildTowerAtStart?):
            Tower.BuildNow()
            Sleep(3.0)

        for (Spawner : NormalSpawners):
            Spawner.Disable()
            Spawner.EliminatedEvent.Subscribe(OnGuardEliminated)
        for (Spawner : MeleeSpawners):
            Spawner.Disable()
            Spawner.EliminatedEvent.Subscribe(OnGuardEliminated)
        BossAddsSpawner.Disable()
        BossAddsSpawner.EliminatedEvent.Subscribe(OnGuardEliminated)
        HadesSpawner.Disable()
        HadesSpawner.EliminatedEvent.Subscribe(OnHadesEliminated)

        for (Pad : PlayerSpawnPads):
            Pad.SpawnedEvent.Subscribe(OnPlayerRespawned)

        RunGame()

    RunGame()<suspends> : void =
        ShowHUD("WELCOME TO THE OLYMPUS GRAND CASINO", 5.0)
        Sleep(5.0)

        for (FloorIndex := 0..8):
            RunCombatFloor(FloorIndex)
            Sleep(IntermissionSeconds)

        RunHadesFloor()

    RunCombatFloor(FloorIndex : int)<suspends> : void =
        set CurrentFloorIndex = FloorIndex
        FloorNumber := FloorIndex + 1
        TotalEnemies := BaseEnemiesPerFloor + (EnemiesAddedPerFloor * FloorIndex)
        var MaxAlive : int = BaseSimultaneousEnemies + FloorIndex
        if (MaxAlive > 10):
            set MaxAlive = 10
        MeleePercent := MeleeGuardPercent

        TeleportAllPlayersToFloor(FloorIndex)
        WeaponName := GetWeaponName(FloorIndex)
        ShowHUD("FLOOR {FloorNumber} — {WeaponName} — {TotalEnemies} ENEMIES INBOUND", 6.0)
        GrantWeaponToAll(FloorIndex)
        Sleep(2.0)

        set ElimCount = 0
        var SpawnedCount : int = 0
        EnableFloor(FloorIndex)

        loop:
            if (SpawnedCount >= MaxAlive or SpawnedCount >= TotalEnemies):
                break
            SpawnOneEnemy(FloorIndex, MeleePercent)
            set SpawnedCount += 1
            Sleep(0.3)

        loop:
            ElimSignal.Await()
            Remaining := TotalEnemies - ElimCount
            if (Remaining <= 0):
                break
            if (Remaining * 2 = TotalEnemies):
                ShowHUD("{Remaining} ENEMIES REMAINING", 3.0)
            else if (Remaining = 5):
                ShowHUD("{Remaining} ENEMIES REMAINING", 3.0)
            if (SpawnedCount < TotalEnemies):
                SpawnOneEnemy(FloorIndex, MeleePercent)
                set SpawnedCount += 1

        DisableFloor(FloorIndex)
        ShowHUD("FLOOR {FloorNumber} CLEARED! ASCENDING...", 4.0)

    RunHadesFloor()<suspends> : void =
        set CurrentFloorIndex = 9
        TeleportAllPlayersToFloor(9)
        ShowHUD("FLOOR 10 — THE HELIPAD. HADES RISES, CHAINS IN HAND.", 6.0)
        Sleep(3.0)
        ShowHUD("THE THUNDERBOLT OF ZEUS IS YOURS. SEND HIM BACK TO THE UNDERWORLD.", 6.0)

        GrantWeaponToAll(9)

        set HadesDown = false
        HadesSpawner.Enable()
        BossAddsSpawner.Enable()
        for (AddIndex := 0..2):
            BossAddsSpawner.Reset()
            BossAddsSpawner.Spawn()

        loop:
            ElimSignal.Await()
            if (HadesDown?):
                break

        BossAddsSpawner.Disable()
        ShowHUD("HADES HAS FALLEN. THE HOUSE ALWAYS LOSES.", 6.0)
        Sleep(4.0)

        if (Winner := LastKiller?):
            VictoryDevice.Activate(Winner)
        else if (FirstPlayer := GetPlayspace().GetPlayers()[0]):
            VictoryDevice.Activate(FirstPlayer)

    OnGuardEliminated(Result : device_ai_interaction_result) : void =
        set ElimCount += 1
        ElimSignal.Signal()

    OnHadesEliminated(Result : device_ai_interaction_result) : void =
        set HadesDown = true
        if (Killer := Result.Source?):
            set LastKiller = option{Killer}
        ElimSignal.Signal()

    OnPlayerRespawned(Agent : agent) : void =
        Destination := Tower.GetFloorArrivalPosition(CurrentFloorIndex)
        FacingIn := MakeRotationFromYawPitchRollDegrees(90.0, 0.0, 0.0)
        if (Character := Agent.GetFortCharacter[]):
            if (Character.TeleportTo[Destination, FacingIn]) {}
            Character.SetHealth(Character.GetMaxHealth())
            Character.SetShield(Character.GetMaxShield())
        if (Granter := FloorWeaponGranters[CurrentFloorIndex]):
            Granter.GrantItem(Agent)

    TeleportAllPlayersToFloor(FloorIndex : int) : void =
        Destination := Tower.GetFloorArrivalPosition(FloorIndex)
        FacingIn := MakeRotationFromYawPitchRollDegrees(90.0, 0.0, 0.0)
        for (Player : GetPlayspace().GetPlayers()):
            if (Character := Player.GetFortCharacter[]):
                if (Character.TeleportTo[Destination, FacingIn]) {}
                else:
                    Print("Teleport failed for a player")
                Character.SetHealth(Character.GetMaxHealth())
                Character.SetShield(Character.GetMaxShield())

    SpawnOneEnemy(FloorIndex : int, MeleePercent : int) : void =
        Roll := GetRandomInt(0, 99)
        if (Roll < MeleePercent, Melee := MeleeSpawners[FloorIndex]):
            Melee.Reset()
            Melee.Spawn()
        else if (Normal := NormalSpawners[FloorIndex]):
            Normal.Reset()
            Normal.Spawn()

    EnableFloor(FloorIndex : int) : void =
        if (Normal := NormalSpawners[FloorIndex]):
            Normal.Enable()
        if (Melee := MeleeSpawners[FloorIndex]):
            Melee.Enable()

    DisableFloor(FloorIndex : int) : void =
        if (Normal := NormalSpawners[FloorIndex]):
            Normal.Disable()
        if (Melee := MeleeSpawners[FloorIndex]):
            Melee.Disable()

    GrantWeaponToAll(FloorIndex : int) : void =
        if (Granter := FloorWeaponGranters[FloorIndex]):
            for (Player : GetPlayspace().GetPlayers()):
                Granter.GrantItem(Player)

    GetWeaponName(FloorIndex : int) : string =
        if (Name := FloorWeaponNames[FloorIndex]):
            return Name
        return "MYSTERY WEAPON"

    ShowHUD(Text : string, Duration : float) : void =
        FloorHUD.SetText(StringToMessage(Text))
        FloorHUD.SetDisplayTime(Duration)
        FloorHUD.Show()

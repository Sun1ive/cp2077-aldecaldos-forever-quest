
@addMethod(PlayerPuppet)
public func ASpawnExplodeCar() {
    let CoreService = GameInstance.GetScriptableServiceContainer().GetService(n"CoreService") as CoreService;
    CoreService.SpawnExplodeCar();
}

class CoreService extends ScriptableService {
    private let m_explode_vehicle: EntityID;
    private let core: ref<CoreSystem>;

    public func GetCore() -> ref<CoreSystem> {
        if Equals(IsDefined(this.core), false) {
            this.core = new CoreSystem();
        }
        return this.core;
    }

    public func SpawnExplodeCar() -> Void {
        let tagService = GameInstance.GetScriptableServiceContainer().GetService(n"TagService") as TagService;
        this.m_explode_vehicle = this
            .GetCore()
            .Spawn(
                t"Vehicle.q000_nomad_v_utility4_militech_behemoth_quest",
                new Vector4(-2836.1377, -4194.192, 68.5278, 1),
                [tagService.GetExplodeCarTag()],
                n"militech_behemoth_basic_base_01",
                new Quaternion(0, 0, 0.8979599, -0.4400776)
            );
    }
}

class TagService extends ScriptableService {
    public func GetQuestTag() -> CName {
        return n"sq_high_stakes";
    }

    public func GetExplodeCarTag() -> CName {
        return n"sq_high_stakes_explode_car";
    }
}

class CoreSystem extends ScriptableSystem {
    private let m_entitySystem: wref<DynamicEntitySystem>;
    private let m_callbackSystem: wref<CallbackSystem>;

    public func HasSpaceForSpawning() -> Bool {
        return !IsEntityInInteriorArea(this.GetPlayer()) && SpatialQueriesHelper.HasSpaceInFront(this.GetPlayer(), 0.1, 10.0, 10.0, 2.0);
    }

    public func GetPlayer() -> ref<PlayerPuppet> {
        return GetPlayer(GetGameInstance());
    }

    public func GetDirection(angle: Float) -> Vector4 {
        return Vector4
            .RotateAxis(
                this.GetPlayer().GetWorldForward(),
                new Vector4(0, 0, 1, 0),
                angle / 180.0 * Pi()
            );
    }

    public func GetPosition(distance: Float, angle: Float) -> Vector4 {
        return this.GetPlayer().GetWorldPosition() + this.GetDirection(angle) * distance;
    }

    public func GetOrientation(angle: Float) -> Quaternion {
        return EulerAngles.ToQuat(Vector4.ToRotation(this.GetDirection(angle)));
    }

    private func OnAttach() {
        this.m_entitySystem = GameInstance.GetDynamicEntitySystem();
        this.m_callbackSystem = GameInstance.GetCallbackSystem();
        let tagService = GameInstance.GetScriptableServiceContainer().GetService(n"TagService") as TagService;

        this
            .m_callbackSystem
            .RegisterCallback(n"Entity/Attached", this, n"OnEntityAttached")
            .AddTarget(DynamicEntityTarget.Tag(tagService.GetQuestTag()));
        this
            .m_callbackSystem
            .RegisterCallback(n"Entity/Detach", this, n"OnEntityDetached")
            .AddTarget(DynamicEntityTarget.Tag(tagService.GetQuestTag()));
    }

    public func Spawn(
        recordID: TweakDBID,
        position: Vector4,
        tags: array<CName>,
        appearance: CName,
        orientation: Quaternion
    ) -> EntityID {
        let tagService = GameInstance.GetScriptableServiceContainer().GetService(n"TagService") as TagService;
        let npcTags: array<CName> = [tagService.GetQuestTag()];
        for tag in tags {
            ArrayPush(npcTags, tag);
        }
        let npcSpec = new DynamicEntitySpec();
        npcSpec.recordID = recordID;
        npcSpec.appearanceName = appearance;
        npcSpec.position = position;
        npcSpec.orientation = orientation;
        npcSpec.persistState = false;
        npcSpec.persistSpawn = false;
        npcSpec.tags = npcTags;
        return GameInstance.GetDynamicEntitySystem().CreateEntity(npcSpec);
    }

    private cb func OnEntityAttached(event: ref<EntityLifecycleEvent>) {
        let tagService = GameInstance.GetScriptableServiceContainer().GetService(n"TagService") as TagService;
        let baseEnt = event.GetEntity() as GameObject;
        let isExplodeCar = baseEnt.HasTag(tagService.GetExplodeCarTag());
        if Equals(isExplodeCar, true) {
            let ent = event.GetEntity() as VehicleObject;
            if IsDefined(ent) {
                ent.GetVehicleComponent().ExplodeVehicle(ent);
            }
        }
    }

    private cb func OnEntityDetached(event: ref<EntityLifecycleEvent>) {
        let hash = EntityID.GetHash(event.GetEntity().GetEntityID());
        FTLog(s"detached \(hash)");
    }
}

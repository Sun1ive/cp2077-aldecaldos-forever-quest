module AldecaldosHighStakes.QuestVehicle

class QuestVehicleService extends ScriptableService {
    private let m_vehicle_hp: Int32;
    private let m_vehicle_destroyed: Bool;
    private let m_vehicle_object: ref<VehicleObject>;
    // 0 | 1 | 2 | 3 | 4 | 5
    // 0 - initial | 1 - 85% ~ 75% | 2 - 65% - 50% | 3 - 25 ~ 30%  | 4 - 15% ~ 10% | 5 - disabled notification
    private let m_notification_state: Int32;

    private cb func OnLoad() {
        GameInstance
            .GetCallbackSystem()
            .RegisterCallback(n"Session/Ready", this, n"OnSessionReady");
    }

    private cb func OnSessionReady(event: ref<GameSessionEvent>) {
        if !event.IsPreGame() {
            this.m_notification_state = 0;
            this.m_vehicle_hp = -1;
            this.m_vehicle_destroyed = false;
        }
    }

    public func SetVehicle(vehicle: ref<VehicleObject>) -> Void {
        if !this.HasVehicle() {
            this.m_vehicle_object = vehicle;
            this.m_vehicle_hp = 100;
        }
    }

    public func HasVehicle() -> Bool {
        return IsDefined(this.m_vehicle_object);
    }

    public func GetVehicleObject() -> ref<VehicleObject> {
        return this.m_vehicle_object;
    }

    public func ApplyDamage(destruction: Float) -> Void {
        this.m_vehicle_hp = Cast<Int32>(destruction);
        if this.m_vehicle_hp == 0 {
            this.m_vehicle_destroyed = true;
        }
        this.AlertPlayer();
    }

    public func AlertPlayer() -> Void {
        if this.m_vehicle_hp <= 100 && this.m_vehicle_hp >= 85 && this.m_notification_state == 0 {
            this.m_notification_state = 1;
            this
                .ShowNotification(
                    GetLocalizedText(s"LocKey#9436066804195855013") + this.m_vehicle_hp + "%"
                );
        }
        if this.m_vehicle_hp <= 85 && this.m_vehicle_hp >= 75 && this.m_notification_state == 1 {
            this.m_notification_state = 2;
            this
                .ShowNotification(
                    GetLocalizedText(s"LocKey#7846835637855334049") + this.m_vehicle_hp + "%"
                );
        }
        if this.m_vehicle_hp <= 65 && this.m_vehicle_hp >= 50 && this.m_notification_state == 2 {
            this.m_notification_state = 3;
            this
                .ShowNotification(
                    GetLocalizedText(s"LocKey#5704945695707168034") + this.m_vehicle_hp + "%"
                );
        }
        if this.m_vehicle_hp <= 30 && this.m_vehicle_hp >= 25 && this.m_notification_state == 3 {
            this
                .ShowNotification(
                    GetLocalizedText(s"LocKey#9322729103479920025") + this.m_vehicle_hp + "%"
                );
            this.m_notification_state = 4;
        }
        if this.m_vehicle_hp <= 15 && this.m_vehicle_hp >= 10 && this.m_notification_state == 4 {
            this
                .ShowNotification(
                    GetLocalizedText(s"LocKey#17921965581097729998") + this.m_vehicle_hp + "%"
                );
            this.m_notification_state = 5;
        }
    }

    public func IsQuestVehicle(recordId: TweakDBID) -> Bool {
        return Equals(t"Vehicle.sq_hs_behemoth", recordId);
    }

    public func ShowNotification(message: String) -> Void {
        let msg = new SimpleScreenMessage();
        msg.duration = 3;
        msg.message = message;
        msg.isShown = true;
        msg.type = SimpleMessageType.Negative;
        GetGameInstance()
            .GetBlackboardSystem()
            .Get(GetAllBlackboardDefs().UI_Notifications)
            .SetVariant(GetAllBlackboardDefs().UI_Notifications.WarningMessage, msg, true);
    }
}

@wrapMethod(VehicleComponent)
private final func EvaluateDamageLevel(destruction: Float) -> Int32 {
    let result: Int32 = wrappedMethod(destruction);
    let vehicleService = GameInstance
        .GetScriptableServiceContainer()
        .GetService(n"AldecaldosHighStakes.QuestVehicle.QuestVehicleService") as QuestVehicleService;
    let recordId = this.GetVehicle().GetRecordID();
    if vehicleService.HasVehicle() && vehicleService.IsQuestVehicle(recordId) {
        vehicleService.ApplyDamage(destruction);
    }

    return result;
}

@wrapMethod(PlayerPuppet)
protected cb func OnMountingEvent(evt: ref<MountingEvent>) -> Bool {
    let vehicleService = GameInstance
        .GetScriptableServiceContainer()
        .GetService(n"AldecaldosHighStakes.QuestVehicle.QuestVehicleService") as QuestVehicleService;
    let result: Bool = wrappedMethod(evt);
    let vehicle = this.GetMountedVehicle();
    if IsDefined(vehicle) {
        let recordId = vehicle.GetRecordID();
        if vehicleService.IsQuestVehicle(recordId) {
            vehicleService.SetVehicle(vehicle);
        }
    }

    return result;
}

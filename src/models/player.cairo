use starknet::ContractAddress;

const MAX_PLAYER_ITEMS: u8 = 8;

#[derive(Copy, Drop, Serde, Introspect, PartialEq)]
enum PlayerState {
    Idle: (),
    Handcuffed: (),
}

impl PlayerStateFelt252 of Into<PlayerState, felt252> {
    fn into(self: PlayerState) -> felt252 {
        match self {
            PlayerState::Idle => 0,
            PlayerState::Handcuffed => 1,
        }
    }
}

#[derive(Copy, Drop, Serde, Introspect, PartialEq)]
enum Item {
    // Shotgun deals 2x damage
    Knife: (),
    // Cigarette heals 1 hp
    Cigarette: (),
    // Glasses let you look at racked bullet
    Glasses: (),
    // Skips your turn
    Drink: (),
    // Handcuffs a player. Skips their turn
    Handcuffs: (),
}

impl ItemFelt252 of Into<Item, felt252> {
    fn into(self: Item) -> felt252 {
        match self {
            Item::Knife => 0,
            Item::Cigarette => 1,
            Item::Glasses => 2,
            Item::Drink => 3,
            Item::Handcuffs => 4,
        }
    }
}


#[derive(Model, Copy, Drop, Serde)]
struct Player {
    #[key]
    game_id: u32,
    #[key]
    player_id: u8,

    address: ContractAddress,

    health: u8,

    // count of each item
    // the player has
    knives: u8,
    cigarettes: u8,
    glasses: u8,
    drinks: u8,
    handcuffs: u8,
}

#[generate_trait]
impl PlayerImpl of PlayerTrait {
    fn assert_caller(self: Player, caller: ContractAddress) {
        assert(self.address == caller, 'Not player')
    }

    fn assert_alive(self: Player) {
        assert(self.health > 0, 'Player is dead')
    }

    fn assert_can_play(self: Player) {
        self.assert_alive();
    }

    fn assert_can_use(self: Player, item: Item) {
        match item {
            Item::Knife => assert(self.knives > 0, 'Player has no knives'),
            Item::Cigarette => assert(self.cigarettes > 0, 'Player has no cigarettes'),
            Item::Glasses => assert(self.glasses > 0, 'Player has no glasses'),
            Item::Drink => assert(self.drinks > 0, 'Player has no drinks'),
            Item::Handcuffs => assert(self.handcuffs > 0, 'Player has no handcuffs'),
        }
    }
}
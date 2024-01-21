use starknet::ContractAddress;

const MAX_PLAYER_ITEMS: u8 = 8;

#[derive(Copy, Drop, Serde, Introspect)]
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

#[derive(Copy, Drop, Serde, Introspect)]
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
    player_id: ContractAddress,

    health: u8,
    state: PlayerState,

    // count of each item
    // the player has
    knives: u8,
    cigarettes: u8,
    glasses: u8,
    drinks: u8,
    handcuffs: u8,
}
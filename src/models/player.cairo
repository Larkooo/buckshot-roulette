use starknet::ContractAddress;

const PLAYER_HEALTH: u8 = 3;
const MAX_PLAYER_ITEMS: u8 = 8;

#[derive(Copy, Drop, Serde, Introspect, PartialEq)]
enum GamePlayerState {
    Idle: (),
    Handcuffed: (),
}

impl GamePlayerStateFelt252 of Into<GamePlayerState, felt252> {
    fn into(self: GamePlayerState) -> felt252 {
        match self {
            GamePlayerState::Idle => 0,
            GamePlayerState::Handcuffed => 1,
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
    player_id: ContractAddress,

    game_id: u32,
    game_player_id: u8,
}

#[generate_trait]
impl PlayerImpl of PlayerTrait {
    fn assert_can_join(self: Player) {
        assert(self.game_id == 0, 'Player is already in a game')
    }
}

#[derive(Model, Copy, Drop, Serde)]
struct GamePlayer {
    #[key]
    game_id: u32,
    #[key]
    player_id: u8,

    address: ContractAddress,

    health: u8,
    score: u8,

    // count of each item
    // the player has
    knives: u8,
    cigarettes: u8,
    glasses: u8,
    drinks: u8,
    handcuffs: u8,
}

#[generate_trait]
impl GamePlayerImpl of GamePlayerTrait {
    fn assert_caller(self: GamePlayer, caller: ContractAddress) {
        assert(self.address == caller, 'Not player')
    }

    fn assert_alive(self: GamePlayer) {
        assert(self.health > 0, 'GamePlayer is dead')
    }

    fn assert_can_play(self: GamePlayer) {
        self.assert_alive();
    }

    fn assert_can_use(self: GamePlayer, item: Item) {
        match item {
            Item::Knife => assert(self.knives > 0, 'GamePlayer has no knives'),
            Item::Cigarette => assert(self.cigarettes > 0, 'GamePlayer has no cigarettes'),
            Item::Glasses => assert(self.glasses > 0, 'GamePlayer has no glasses'),
            Item::Drink => assert(self.drinks > 0, 'GamePlayer has no drinks'),
            Item::Handcuffs => assert(self.handcuffs > 0, 'GamePlayer has no handcuffs'),
        }
    }
}
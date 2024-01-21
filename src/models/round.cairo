use starknet::ContractAddress;

struct Shotgun {
    real_bullets: u32,
    fake_bullets: u32,
}

#[derive(Model, Copy, Drop, Serde)]
struct Round {
    #[key]
    game_id: u32,
    #[key]
    round_id: u8,

    current_turn: ContractAddress,
    shotgun: Shotgun,
}

#[derive(Model, Copy, Drop, Serde)]
struct Player {
    #[key]
    game_id: u32,
    #[key]
    round_id: u8,
    #[key]
    player_id: ContractAddress,
    health: u8,
    
    // count of each item
    // the player has
    knives: u8,
    cigarettes: u8,
    glasses: u8,
    drinks: u8,
}
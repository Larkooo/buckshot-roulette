#[derive(Model, Copy, Drop, Serde)]
struct Game {
    #[key]
    game_id: u32,

    // 0 is the lobby.
    // waiting for another player to join.
    current_round: u8,
    number_of_rounds: u8,

    player1: ContractAddress,
    player2: ContractAddress,
}
#[derive(Model, Copy, Drop, Serde)]
struct Game {
    #[key]
    game_id: u32,

    // 0 is the lobby.
    // waiting for another player to join.
    current_round: u8,
    number_of_rounds: u8,
}

#[generate_trait]
impl GameImpl of GameTrait {
    fn assert_lobby(self: Game) {
        assert(self.current_round == 0, 'Game is not in the lobby.');
    }

    fn is_first_round(self: Game) -> bool {
        self.current_round == 1
    }

    fn is_last_round(self: Game) -> bool {
        self.current_round == self.number_of_rounds
    }
}
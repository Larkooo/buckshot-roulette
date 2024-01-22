use buckshot_roulette::models::{round::Shotgun};
use core::poseidon::PoseidonTrait;
use core::hash::{HashStateTrait, HashStateExTrait};

#[derive(Model, Copy, Drop, Serde)]
struct Game {
    #[key]
    game_id: u32,
    // 0 is the lobby.
    // waiting for another player to join.
    current_round: u8,
    rounds: u8,
    players: u8,
    max_players: u8,
    winner: u8,
}

#[generate_trait]
impl GameImpl of GameTrait {
    fn assert_lobby(self: Game) {
        assert(self.current_round == 0, 'Game is not in the lobby.');
    }

    fn assert_started(self: Game) {
        assert(self.current_round > 0, 'Game has not started.');
    }

    fn is_first_round(self: Game) -> bool {
        self.current_round == 1
    }

    fn is_last_round(self: Game) -> bool {
        self.current_round == self.rounds
    }

    fn assert_can_join(self: Game) {
        self.assert_lobby();
        assert(self.players < self.max_players, 'Game is full.');
    }
}

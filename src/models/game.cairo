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

    shotgun_nonce: felt252,
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

    fn generate_shotgun(ref self: Game) -> Shotgun {
        let mut state = PoseidonTrait::new();
        state.update(self.game_id.into());
        state.update(self.current_round.into());
        state.update(self.rounds.into());
        state.update(self.shotgun_nonce);
        self.shotgun_nonce += 1;

        let random: u256 = state.finalize().into();
        // we split the random number into 2 128-bit numbers.
        let random1 = random & 0xffffffffffffffffffffffffffffffff;
        // cant use shift here because it is not supported in felt.
        let random2 = random - random1;

        // we can have a maximum of 10 bullets.
        Shotgun {
            seed: random,
            real_bullets: (random1 % 5 + 1).try_into().unwrap(),
            fake_bullets: (random2 % 5 + 1).try_into().unwrap(),
            nonce: 0,
        }
    }
}
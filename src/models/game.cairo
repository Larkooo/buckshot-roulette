use starknet::PoseidonTrait;

#[derive(Model, Copy, Drop, Serde)]
struct Game {
    #[key]
    game_id: u32,

    // 0 is the lobby.
    // waiting for another player to join.
    current_round: u8,
    number_of_rounds: u8,

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
        self.current_round == self.number_of_rounds
    }

    fn generate_shotgun(self: Game) -> Shotgun {
        let mut state = PoseidonTrait::new();
        state.update(self.game_id);
        state.update(self.current_round);
        state.update(self.number_of_rounds);
        state.update(self.shotgun_nonce);
        self.shotgun_nonce += 1;

        let random: u256 = state.finalize().into();
        // we split the random number into 2 128-bit numbers.
        let random1: u128 = (random & 0xffffffffffffffffffffffffffffffff).try_into().unwrap();
        // cant use shift here because it is not supported in felt.
        let random2: u128 = (random - random1).try_into().unwrap();

        // we can have a maximum of 10 bullets.
        Shotgun {
            random1: (random1 % 5 + 1).try_into().unwrap(),
            random2: (random2 % 5 + 1).try_into().unwrap(),
        }
    }
}
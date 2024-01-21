use starknet::{ContractAddress};
use core::poseidon::PoseidonTrait;
use core::hash::{HashStateTrait, HashStateExTrait};

const MAX_BULLETS: u32 = 10;

#[derive(Copy, Drop, Serde, Introspect)]
struct Shotgun {
    seed: u256,
    real_bullets: u32,
    fake_bullets: u32,
    nonce: felt252,
}

#[generate_trait]
impl ShotgunImpl of ShotgunTrait {
    fn shoot(ref self: Shotgun, target: ContractAddress) -> bool {
        assert(self.real_bullets > 0 && self.fake_bullets > 0, 'No more boullets');

        let mut state = PoseidonTrait::new();
        state.update(self.seed.try_into().unwrap());
        state.update(self.real_bullets.into());
        state.update(self.fake_bullets.into());
        state.update(self.nonce);
        state.update(target.into());

        let random = state.finalize().try_into().unwrap() % 2;
        let is_real = random == 1;

        self.real_bullets -= random;
        self.fake_bullets -= 1 - random;

        self.nonce += 1;

        is_real
    }
}

#[derive(Model, Copy, Drop, Serde)]
struct Round {
    #[key]
    game_id: u32,
    #[key]
    round_id: u8,

    dead_players: u8,

    current_turn: u32,
    shotgun: Shotgun,

    winner: u8,
}



#[generate_trait]
impl RoundImpl of RoundTrait {
    fn assert_ongoing(self: Round, player_count: u8) {
        assert(self.dead_players < player_count, 'Round is over');
    }

    fn assert_turn(self: Round, player_id: u8, player_count: u8) {
        self.assert_ongoing(player_count);
        assert(player_id == ((self.current_turn).try_into().unwrap() % player_count), 'Not your turn');
    }

    fn current_player(self: Round, player_count: u8) -> u8 {
        self.assert_ongoing(player_count);
        (self.current_turn).try_into().unwrap() % player_count
    }
}
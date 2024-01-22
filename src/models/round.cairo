use starknet::{ContractAddress};
use core::poseidon::PoseidonTrait;
use core::hash::{HashStateTrait, HashStateExTrait};

const MAX_BULLETS: u32 = 10;

#[derive(Copy, Drop, Serde, Introspect)]
struct Shotgun {
    seed: u256,
    real_bullets: u8,
    fake_bullets: u8,
    nonce: felt252,
}

#[generate_trait]
impl ShotgunImpl of ShotgunTrait {
    fn new() -> Shotgun {
        Shotgun {
            seed: 0,
            real_bullets: 0,
            fake_bullets: 0,
            nonce: 0,
        }
    }

    fn shoot(ref self: Shotgun, target: ContractAddress) -> bool {
        assert(self.real_bullets > 0 && self.fake_bullets > 0, 'No more boullets');

        let mut state = PoseidonTrait::new();
        state = state.update(self.seed.try_into().unwrap());
        state = state.update(self.real_bullets.into());
        state = state.update(self.fake_bullets.into());
        state = state.update(target.into());
        state = state.update(self.nonce);
        self.nonce += 1;

        let random: u256 = state.finalize().into();
        let random: u8 = (random % 2).try_into().unwrap();
        let is_real = random == 1;

        self.real_bullets -= random;
        self.fake_bullets -= 1 - random;

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
    shotgun_nonce: felt252,
    
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

    fn new_shotgun(ref self: Round, seed: felt252) {
        assert(self.shotgun.real_bullets == 0 && self.shotgun.fake_bullets == 0, 'Shotgun is not empty');
        
        let mut state = PoseidonTrait::new();
        state = state.update(seed);
        state = state.update(self.round_id.into());
        state = state.update(self.dead_players.into());
        state = state.update(self.current_turn.into());
        state = state.update(self.shotgun_nonce);
        self.shotgun_nonce += 1;
        
        let random: u256 = state.finalize().into();
        // we split the random number into 2 128-bit numbers.
        let random1 = random.high;
        let random2 = random.low;

        // max of 10 bullets
        self.shotgun = Shotgun {
            seed: random,
            real_bullets: (random1 % 5 + 1).try_into().unwrap(),
            fake_bullets: (random2 % 5 + 1).try_into().unwrap(),
            nonce: 0,
        };
    }
}
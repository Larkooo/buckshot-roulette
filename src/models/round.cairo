use starknet::ContractAddress;

#[derive(Copy, Drop, Serde, Introspect)]
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

#[generate_trait]
impl RoundImpl of RoundTrait {
    fn assert_turn(self: Round, player: ContractAddress) {
        assert(self.current_turn == player, 'Not your turn');
    }
}
#[starknet::interface]
trait IRound<TContractState> {
    fn shoot_yourself(self: @TContractState);
    fn shoot_opponent(self: @TContractState);
}

#[dojo::contract]
mod round {
    use super::IRound;
    use buckshot_roulette::models::{round::Round, game::Game};
    use starknet::{get_caller_address};

    #[external(v0)]
    impl RoundImpl of IRound<ContractState>{
        fn shoot_yourself(self: @ContractState, game_id: u64) {
            let player = get_caller_address();
            let world = self.world_dispatcher.read();

            let game = get!(world, Game, game_id);
            game.assert_started();

            let mut round = get!(world, Round, game.current_round);
            round.assert_turn(player);

            // check if no more shotgun bullets, if so, generate new shotgun
            if round.shotgun.real_bullets == 0 && round.shotgun.fake_bullets == 0 {
                self.shotgun = game.generate_shotgun();
                set!(world, (round));
            }

            let player = get!(world, Player, self.caller);
            // randomize if bullet is real or not

            
        }

        fn shoot_opponent(self: @ContractState) {
            
        }
    }
}

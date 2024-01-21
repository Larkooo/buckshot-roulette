#[starknet::interface]
trait IRound<TContractState> {
    fn shoot_yourself(self: @TContractState);
    fn shoot_opponent(self: @TContractState);
}

#[dojo::contract]
mod round {
    use super::IRound;
    use buckshot_roulette::models::{round::Round, game::Game, round::ShotgunTrait, player::Player};
    use starknet::{get_caller_address};

    #[external(v0)]
    impl RoundImpl of IRound<ContractState>{
        fn shoot(self: @ContractState, game_id: u64, target_player: u8) {
            let caller = get_caller_address();
            let world = self.world_dispatcher.read();

            let game = get!(world, Game, game_id);
            game.assert_started();

            let round = get!(world, Round, (game_id, game.current_round));
            
            let player = get!(world, Player, (game_id, round.current_player(game.player_count - round.dead_players)));
            player.assert_caller(caller);

            let target_player = get!(world, Player, (game_id, target_player));

            // check if no more shotgun bullets, if so, generate new shotgun
            if round.shotgun.real_bullets == 0 && round.shotgun.fake_bullets == 0 {
                round.shotgun = ShotgunTrait::new()
                set!(world, (round));
            } else if round.shotgun.real_bullets == 0 {
                // if no more real bullets, then shoot fake bullet
                round.shotgun.fake_bullets -= 1;
            } else {
                // if real bullets, then shoot real bullet
                round.shotgun.real_bullets -= 1;
                player.health -= 1;
            }

            let is_real = round.shotgun.shoot(caller);
            if is_real {
                player.health -= 1;
            }

            round.current_turn += 1;

            set!(world, (round, player));
        }
    }
}

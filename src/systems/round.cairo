#[starknet::interface]
trait IRound<TContractState> {
    fn shoot(self: @TContractState, game_id: u32, target_player: u8);
}

#[dojo::contract]
mod round {
    use super::IRound;
    use buckshot_roulette::models::{
        round::Round, round::RoundTrait, game::Game, game::GameTrait, round::ShotgunTrait,
        player::GamePlayer, player::GamePlayerTrait, player::Player, player::PlayerTrait,
        round::Shotgun, player::PLAYER_HEALTH
    };
    use starknet::{get_caller_address};
    use core::poseidon::PoseidonTrait;
    use core::hash::{HashStateTrait, HashStateExTrait};

    #[external(v0)]
    impl RoundImpl of IRound<ContractState> {
        fn shoot(self: @ContractState, game_id: u32, target_player: u8) {
            // get caller & world
            let caller = get_caller_address();
            let world = self.world();

            let mut game = get!(world, (game_id), Game);

            // get current round - it also 
            // checks if the game is started as the round has to exist
            let mut round = get!(world, (game_id, game.current_round), Round);

            // get player from the alive player indices
            let alive_players = game.players - round.dead_players;
            let mut player = get!(
                world, (game_id, round.current_player(alive_players)), GamePlayer
            );
            // assert that the player is the caller
            player.assert_caller(caller);
            // assert that the player is alive
            player.assert_alive();

            // get the player to shoot
            let mut target_player = get!(world, (game_id, target_player), GamePlayer);

            let mut increment_turn = true;
            // check if no more shotgun bullets, if so, generate new shotgun
            if round.shotgun.real_bullets == 0 && round.shotgun.fake_bullets == 0 {
                let mut seed = PoseidonTrait::new();
                seed = seed.update(game_id.into());
                seed = seed.update(player.address.into());
                seed = seed.update(target_player.address.into());

                round.new_shotgun(seed.finalize());
            } else if round.shotgun.real_bullets == 0 {
                // if no more real bullets, then shoot fake bullet
                round.shotgun.fake_bullets -= 1;

                // if shot towards self, then dont increment turns 
                // player gets to play again
                if player.player_id == target_player.player_id {
                    increment_turn = false;
                }
            } else if round.shotgun.fake_bullets == 0 {
                // if no more fake bullets, then shoot real bullet
                round.shotgun.real_bullets -= 1;
                target_player.health -= 1;
            } else {
                // shoot random bullet
                let is_real = round.shotgun.shoot(target_player.address);
                if is_real {
                    target_player.health -= 1;
                }
            }

            // check if the player is dead
            if target_player.health == 0 {
                round.dead_players += 1;
            }

            // check if the round is over
            if round.dead_players == game.players - 1 {
                // if so, then end the game
                round.winner = player.player_id;
                player.score += 1;
                // TODO: clean / optimize set calls
                set!(world, (round, player, target_player));

                // check if the game is over
                if game.is_last_round() {
                    // end the game
                    game.end_game(world);
                } else {
                    // if not, then start the next round
                    game.next_round(world, player, target_player);
                }

                return;
            }

            // check if the turn should be incremented
            if increment_turn {
                round.current_turn += 1;
            }

            set!(world, (round, player, target_player));
        }
    }
}

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

    // Calculate winner and 
    // end the game - reset players.
    fn end_game(world: IWorldDispatcher, mut game: Game) {
        let mut best_player = 0;
        let mut current_player_id = 0;
        loop {
            if current_player_id == game.players {
                break;
            }

            let current_player = get!(world, (game.game_id, current_player_id), GamePlayer);
            if current_player.score > best_player {
                best_player = current_player.score;
            }
            current_player_id += 1;

            // reset player
            set!(
                world,
                (Player { player_id: current_player.address, game_id: 0, game_player_id: 0, })
            );
        };

        // set the winner
        game.winner = best_player;
        set!(world, (game));
    }

    // End Round
    fn next_round(world: IWorldDispatcher, mut game: Game, player: GamePlayer, target_player: GamePlayer) {
        // if not, then start the next round
        game.current_round += 1;
        let mut round =
            Round {
                game_id: game.game_id,
                round_id: game.current_round,
                dead_players: 0,
                current_turn: 0,
                shotgun: ShotgunTrait::new(),
                shotgun_nonce: 0,
                winner: 0.try_into().unwrap(),
            };


        // generate a new shotgun
        let mut seed = PoseidonTrait::new();
        seed = seed.update(game.game_id.into());
        seed = seed.update(player.address.into());
        seed = seed.update(target_player.address.into());

        round.new_shotgun(seed.finalize());

        set!(world, (game, round));

        // reset players health
        let mut current_player_id = 0;
        loop {
            if current_player_id == game.players {
                break;
            }

            let mut current_player = get!(world, (game.game_id, current_player_id), GamePlayer);
            current_player.health = PLAYER_HEALTH;
            current_player_id += 1;

            // reset player
            set!(world, (current_player));
        };
    }

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
            } else if round.shotgun.fake_bullets == 0 {
                // if real bullets, then shoot real bullet
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
                set!(world, (round, player));

                // check if the game is over
                if game.is_last_round() {
                    // end the game
                    end_game(world, game);
                } else {
                    // if not, then start the next round
                    next_round(world, game, player, target_player);
                }

                return;
            } else {
                // if not, then start the next turn
                round.current_turn += 1;
            }

            set!(world, (game, round, player, target_player));
        }
    }
}

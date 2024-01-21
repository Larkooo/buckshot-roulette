// define the interface
#[starknet::interface]
trait IGame<TContractState> {
    fn create_game(self: @TContractState, rounds: u32, max_players: u8);
    fn join_game(self: @TContractState, game_id: u32);
    fn start_game(self: @TContractState, game_id: u32);
}

// dojo decorator
#[dojo::contract]
mod game {
    use super::IGame;
    use buckshot_roulette::models::{game::{Game, GameTrait}, player::Player, round::Round, round::Shotgun};
    use starknet::{get_caller_address};

    #[external(v0)]
    impl GameImpl of IGame<ContractState> {
        fn create_game(self: @ContractState, rounds: u32, max_players: u8) {
            assert!(rounds <= 10, "Number of rounds must be less than 10");

            // get world
            let world = self.world();

            // generate game uuid
            let game_id = world.uuid();

            // get player address
            let player = get_caller_address();

            // create game
            set!(
                world,
                (Game {
                    game_id,
                    current_round: 0,
                    rounds: rounds.try_into().unwrap(),
                    players: 1,
                    max_players,
                    shotgun_nonce: 0,
                    winner: 0,
                }, Player {
                    game_id,
                    player_id: 0,
                    address: player,
                    health: 8,
                    score: 0,

                    knives: 0,
                    cigarettes: 0,
                    glasses: 0,
                    drinks: 0,
                    handcuffs: 0,
                })
            )
        }

        fn join_game(self: @ContractState, game_id: u32) {
            // get world
            let world = self.world();

            // get player address
            let player = get_caller_address();

            // get game
            let mut game = get!(world, (game_id), Game);

            // check if game is full
            game.assert_can_join();

            game.players += 1;

            // update game
            set!(
                world,
                (
                    game,
                    Player {
                        game_id,
                        player_id: game.players.into(),
                        address: player,
                        health: 8,
                        score: 0,

                        knives: 0,
                        cigarettes: 0,
                        glasses: 0,
                        drinks: 0,
                        handcuffs: 0,
                    }
                )
            )
        }

        fn start_game(self: @ContractState, game_id: u32) {
            // get world
            let world = self.world();

            let caller = get_caller_address();

            // get game
            let mut game = get!(world, (game_id), Game);

            // index 0 is the host
            let player = get!(world, (game_id, 0), Player);

            // check if caller is the host
            assert!(caller == player.address, "Only the host can start the game");

            // minimum 2 players
            assert!(game.players >= 2, "Minimum 2 players required");

            // start game
            game.current_round = 1;
            let round = Round {
                game_id,
                round_id: game.current_round,
                dead_players: 0,
                current_turn: 0,
                shotgun: game.generate_shotgun(),
                winner: 0.try_into().unwrap(),
            };
        }
    }
}
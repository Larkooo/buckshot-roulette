// define the interface
#[starknet::interface]
trait IGame<TContractState> {
    fn start_game(self: @TContractState, number_of_rounds: u32);
    fn join_game(self: @TContractState, game_id: u32);
}

// dojo decorator
#[dojo::contract]
mod game {
    use super::IGame;
    use buckshot_roulette::models::{game::Game};

    #[external(v0)]
    impl GameImpl of IGame<TContractState> {
        fn start_game(self: @TContractState, number_of_rounds: u32) {
            assert!(number_of_rounds <= 10, "Number of rounds must be less than 10");

            // get world
            let world = self.world_dispatcher.read();

            // generate game uuid
            let game_id = uuid!();

            // get player address
            let player = get_caller_address();

            // create game
            set!(
                world,
                Game {
                    game_id,
                    current_round: 0,
                    number_of_rounds,
                    player1: player,
                }
            )
        }

        fn join_game(self: @TContractState, game_id: u32) {
            // get world
            let world = self.world_dispatcher.read();

            // get player address
            let player = get_caller_address();

            // get game
            let game = get!(world, Game, game_id);

            // update game
            set!(
                world,
                (
                    Game { game_id, current_round: 1, player2: player },
                    // First round
                    Round { game_id, round_id: 1, current_turn: player, shotgun: Shotgun {
                        
                    } }
                )
            )
        }
    }
}
use buckshot_roulette::models::{round::Shotgun, round::ShotgunTrait, player::GamePlayer, round::Round, round::RoundTrait, player::Player, player::PLAYER_HEALTH};
use core::poseidon::PoseidonTrait;
use core::hash::{HashStateTrait, HashStateExTrait};
use dojo::world::{IWorldDispatcher, IWorldDispatcherTrait};


#[derive(Model, Copy, Drop, Serde)]
struct Game {
    #[key]
    game_id: u32,
    // 0 is the lobby.
    // waiting for another player to join.
    current_round: u8,
    rounds: u8,
    players: u8,
    max_players: u8,
    winner: u8,
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
        self.current_round == self.rounds
    }

    fn assert_can_join(self: Game) {
        self.assert_lobby();
        assert(self.players < self.max_players, 'Game is full.');
    }

    // Calculate winner and 
    // end the game - reset players.
    fn end_game(ref self: Game, world: IWorldDispatcher) {
        let mut best_player = 0;
        let mut current_player_id = 0;
        loop {
            if current_player_id == self.players {
                break;
            }

            let current_player = get!(world, (self.game_id, current_player_id), GamePlayer);
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
        self.winner = best_player;
        set!(world, (self));
    }

    // End Round
    fn next_round(ref self: Game, world: IWorldDispatcher, player: GamePlayer, target_player: GamePlayer) {
        // if not, then start the next round
        self.current_round += 1;
        let mut round =
            Round {
                game_id: self.game_id,
                round_id: self.current_round,
                dead_players: 0,
                current_turn: 0,
                shotgun: ShotgunTrait::new(),
                shotgun_nonce: 0,
                winner: 0.try_into().unwrap(),
            };


        // generate a new shotgun
        let mut seed = PoseidonTrait::new();
        seed = seed.update(self.game_id.into());
        seed = seed.update(player.address.into());
        seed = seed.update(target_player.address.into());

        round.new_shotgun(seed.finalize());

        set!(world, (self, round));

        // reset players health
        let mut current_player_id = 0;
        loop {
            if current_player_id == self.players {
                break;
            }

            let mut current_player = get!(world, (self.game_id, current_player_id), GamePlayer);
            current_player.health = PLAYER_HEALTH;
            current_player_id += 1;

            // reset player
            set!(world, (current_player));
        };
    }
}

#[starknet::interface]
trait IRound<TContractState> {
    fn shoot_yourself(self: @TContractState);
    fn shoot_opponent(self: @TContractState);
}

#[dojo::contract]
mod round {
    use super::IRound;


    #[external(v0)]
    impl RoundImpl of IRound<ContractState>{
        fn shoot_yourself(self: @ContractState) {
            
        }

        fn shoot_opponent(self: @ContractState) {
            
        }
    }
}

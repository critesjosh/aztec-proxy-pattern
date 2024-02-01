contract LogicContract {
    use dep::aztec::{
        protocol_types::{
            abis::function_selector::FunctionSelector,
            address::AztecAddress,
        },
        context::{PrivateContext, Context},
        state_vars::{  public_state::PublicState,}, 
        types::type_serialization::{ // serialization methods for using booleans and aztec addresses
            address_serialization::{AddressSerializationMethods, AZTEC_ADDRESS_SERIALIZED_LEN},
        }
    };

    struct Storage {
    }

    impl Storage {
        fn init(context: Context) -> Self {
            Storage {
            }}
	}

    #[aztec(private)] 
    fn constructor() {}

    #[aztec(private)]
    fn increment_counter(old_count: Field) -> Field {
        old_count + 1
    }

    #[aztec(public)]
    fn increment_public_counter(old_count: u120) -> u120 {
        old_count + 1
    }

    // not used in this contract, all public state
    unconstrained fn compute_note_hash_and_nullifier(
        contract_address: AztecAddress,
        nonce: Field,
        storage_slot: Field,
        serialized_note: [Field; 0]
    ) -> pub [Field; 4] {
        [0, 0, 0, 0]
    }
}

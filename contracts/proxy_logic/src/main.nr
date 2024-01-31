mod StorageContract;

contract LogicContract {
    use dep::aztec::{
        protocol_types::{
            address::AztecAddress,
        },
        context::{PrivateContext, Context},
        state_vars::{  public_state::PublicState,}, 
        types::type_serialization::{ // serialization methods for using booleans and aztec addresses
            address_serialization::{AddressSerializationMethods, AZTEC_ADDRESS_SERIALIZED_LEN},
        }
    };

    use crate::StorageContract::{
        StorageContractPublicContextInterface,
        StorageContractPrivateContextInterface,
        AddressUpdateAddressStruct
    };

    struct Storage {
        proxy_storage: PublicState<AztecAddress, AZTEC_ADDRESS_SERIALIZED_LEN>,
    }

    impl Storage {
	fn init(context: Context) -> Self {
	    Storage {
            proxy_storage: PublicState::new(context, 1, AddressSerializationMethods),
	    }}
	}
    #[aztec(private)] 
    fn constructor(storage_contract: AztecAddress) {
        assert(!storage_contract.is_zero(), "invalid storage contract address");
        storage.proxy_storage.write(storage_contract);
    }

    #[aztec(private)]
    fn increment_counter(old_count: Field, new_count: Field) {
        let storage_contract = StorageContractPrivateContextInterface::at(storage.proxy_storage.read());
        assert(new_count == old_count + 1, "invalid old count");
        let _ = storage_contract.update_counter(&mut context, old_count, new_count);
    }

    #[aztec(public)]
    fn increment_public_counter(old_count: u120, new_count: u120) {
        let storage_contract = StorageContractPublicContextInterface::at(storage.proxy_storage.read());
        assert(new_count == old_count + 1, "invalid old count");
        let _ = storage_contract.update_public_counter(context, old_count as Field, new_count as Field);
    }

    #[aztec(public)]
    fn set_address(address: AztecAddress) {
        let storage_contract = StorageContractPublicContextInterface::at(storage.proxy_storage.read());
        let _ = storage_contract.update_address(
            context,
            AddressUpdateAddressStruct { inner: address.to_field() },
            true
        );
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

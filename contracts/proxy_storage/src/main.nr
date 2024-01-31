mod types;

contract StorageContract {
    use dep::safe_math::SafeU120;
    use dep::aztec::{
        protocol_types::{
            abis::function_selector::FunctionSelector,
            address::AztecAddress,
        },
        note::{
            note_getter_options::NoteGetterOptions,
            note_header::NoteHeader,
            utils as note_utils,
        },
        context::{PrivateContext, Context},
        state_vars::{ map::Map, public_state::PublicState,immutable_singleton::ImmutableSingleton, singleton::Singleton}, 
        types::type_serialization::{ // serialization methods for using booleans and aztec addresses
            bool_serialization::{BoolSerializationMethods, BOOL_SERIALIZED_LEN},
            address_serialization::{AddressSerializationMethods, AZTEC_ADDRESS_SERIALIZED_LEN},
            field_serialization::{ FieldSerializationMethods, FIELD_SERIALIZED_LEN},
        }
    };
    use dep::field_note::field_note::{FieldNote, FieldNoteMethods, FIELD_NOTE_LEN};

    use crate::types::{
        safe_u120_serialization::{SafeU120SerializationMethods, SAFE_U120_SERIALIZED_LEN}
    };

    struct Storage {
        addresses: Map<AztecAddress, PublicState<bool, BOOL_SERIALIZED_LEN>>,
        public_counter: PublicState<SafeU120, SAFE_U120_SERIALIZED_LEN>,
        counter: Singleton<FieldNote, FIELD_NOTE_LEN>,
    }

    impl Storage {
	fn init(context: Context) -> Self {
	    Storage {
            addresses: Map::new(
                    context,
                    1,
                    |context, slot| {
                        PublicState::new(
                            context,
                            slot,
                            BoolSerializationMethods,
                        )
                    },
                ),
            public_counter: PublicState::new(
                context,
                2,
                SafeU120SerializationMethods,
            ),
            counter: Singleton::new(context, 3, FieldNoteMethods),
	    } }
	}
    #[aztec(private)] 
    fn constructor() {}

    #[aztec(private)]
    fn update_counter(old_count: Field, new_count: Field) {
        assert(storage.counter.get_note(true).value == old_count, "old count does not match");
        let mut new_counter = FieldNote::new(new_count);
        storage.counter.replace(&mut new_counter, true);
    }

    #[aztec(public)]
    fn update_public_counter(old_count: Field, new_count: Field) {
        assert(storage.public_counter.read().value as Field == old_count, "old count does not match");
        let count = SafeU120::new(new_count);
        storage.public_counter.write(count);
    }

    #[aztec(public)]
    fn update_address(address: AztecAddress, value: bool) {
        storage.addresses.at(address).write(value);
    }

    unconstrained fn get_counter() -> pub Field {
        storage.counter.get_note(true).value
    }

    unconstrained fn get_public_counter() -> pub u120 {
        storage.public_counter.read().value
    }

    unconstrained fn get_address(address: AztecAddress) -> pub bool {
        storage.addresses.at(address).read()
    }

    unconstrained fn compute_note_hash_and_nullifier(
        contract_address: AztecAddress,
        nonce: Field,
        storage_slot: Field,
        serialized_note: [Field; 0]
    ) -> pub [Field; 4] {
        let note_header = NoteHeader::new(contract_address, nonce, storage_slot);
        note_utils::compute_note_hash_and_nullifier(FieldNoteMethods, note_header, serialized_note)
    }
}

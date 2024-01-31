mod public_key_note;
mod interfaces;

// Account contract that uses Schnorr signatures for authentication.
// The signing key is stored in an immutable private note and should be different from the encryption/nullifying key.
contract SchnorrAccount {
    use dep::std;
    use dep::std::option::Option;

    use dep::aztec::protocol_types::address::AztecAddress;

    use dep::aztec::{
        context::{PrivateContext, Context},
        note::{ note_header::NoteHeader, utils as note_utils },
        oracle::get_public_key::get_public_key,
        state_vars::{ map::Map, public_state::PublicState,immutable_singleton::ImmutableSingleton}, 
        types::type_serialization::{ // serialization methods for using booleans and aztec addresses
            bool_serialization::{BoolSerializationMethods, BOOL_SERIALIZED_LEN},
            address_serialization::{AddressSerializationMethods, AZTEC_ADDRESS_SERIALIZED_LEN},
            field_serialization::{ FieldSerializationMethods, FIELD_SERIALIZED_LEN},
        },
        protocol_types::{
            abis::function_selector::FunctionSelector,
        }
    };
    use dep::authwit:: {
        entrypoint::{ EntrypointPayload, ENTRYPOINT_PAYLOAD_SIZE },
        account::AccountActions,
        auth_witness::get_auth_witness,
    };

    use crate::public_key_note::{PublicKeyNote, PublicKeyNoteMethods, PUBLIC_KEY_NOTE_LEN};
    use dep::field_note::field_note::{FieldNote, FieldNoteMethods, FIELD_NOTE_LEN};

    struct Storage {
        // docs:start:storage
        signing_public_key: ImmutableSingleton<PublicKeyNote, PUBLIC_KEY_NOTE_LEN>,
        // docs:end:storage
        slow_update: ImmutableSingleton<FieldNote, FIELD_NOTE_LEN>,
        public_slow_update: PublicState<AztecAddress, AZTEC_ADDRESS_SERIALIZED_LEN>,
    }

    impl Storage {
        fn init(context: Context) -> Self {
            Storage {
                signing_public_key: ImmutableSingleton::new(context, 1, PublicKeyNoteMethods),
                // ACCOUNT_ACTIONS is slot 2
                slow_update: ImmutableSingleton::new(context, 3, FieldNoteMethods),
                public_slow_update: PublicState::new(
                    context,
                    4,
                    AddressSerializationMethods,
                ),
            }
        }
    }

    global ACCOUNT_ACTIONS_STORAGE_SLOT = 2;

    // Constructs the contract
    #[aztec(private)]
    fn constructor(
        signing_pub_key_x: pub Field,
        signing_pub_key_y: pub Field,
        slow_updates_contract: AztecAddress
    ) {
        let this = context.this_address();
        let mut pub_key_note = PublicKeyNote::new(signing_pub_key_x, signing_pub_key_y, this);
        storage.signing_public_key.initialize(&mut pub_key_note, true);

        let mut slow_note = FieldNote::new(slow_updates_contract.to_field());
        storage.slow_update.initialize(&mut slow_note, false);

        context.call_public_function(
            // we cannot update public state directly from private function but we can call public function (which queues it)
            context.this_address(),// contract address whose method we want to call
            FunctionSelector::from_signature("_initialize((Field))"), // function selector
            [slow_updates_contract.to_field()] // parameters
        );
    }

    // Note: If you globally change the entrypoint signature don't forget to update default_entrypoint.ts file
    #[aztec(private)]
    fn entrypoint(payload: pub EntrypointPayload) {
        let actions = AccountActions::private(&mut context, ACCOUNT_ACTIONS_STORAGE_SLOT, is_valid_impl);
        actions.entrypoint(payload);
    }

    #[aztec(private)]
    fn is_valid(message_hash: Field) -> Field {
        let actions = AccountActions::private(&mut context, ACCOUNT_ACTIONS_STORAGE_SLOT, is_valid_impl);
        actions.is_valid(message_hash)
    }

    #[aztec(public)]
    fn is_valid_public(message_hash: Field) -> Field {
        let actions = AccountActions::public(&mut context, ACCOUNT_ACTIONS_STORAGE_SLOT, is_valid_impl);
        actions.is_valid_public(message_hash)
    }

    #[aztec(public)]
    internal fn set_is_valid_storage(message_hash: Field, value: bool) {
        let actions = AccountActions::public(&mut context, ACCOUNT_ACTIONS_STORAGE_SLOT, is_valid_impl);
        actions.internal_set_is_valid_storage(message_hash, value)
    }

    #[contract_library_method]
    fn is_valid_impl(context: &mut PrivateContext, message_hash: Field) -> pub bool {
        // docs:start:entrypoint
        // Load public key from storage
        let storage = Storage::init(Context::private(context));
        // docs:start:get_note
        let public_key = storage.signing_public_key.get_note();
        // docs:end:get_note
        // Load auth witness
        let witness: [Field; 64] = get_auth_witness(message_hash);
        let mut signature: [u8; 64] = [0; 64];
        for i in 0..64 {
            signature[i] = witness[i] as u8;
        }

        // Verify signature of the payload bytes
        let verification = std::schnorr::verify_signature(
            public_key.x,
            public_key.y,
            signature,
            message_hash.to_be_bytes(32)
        );
        assert(verification == true);
        // docs:end:entrypoint
        true
    }

    // Computes notes hash and nullifier.
    // Note 1: Needs to be defined by every contract producing logs.
    // Note 2: Having it in all the contracts gives us the ability to compute the note hash and nullifier differently for different kind of notes.
    unconstrained fn compute_note_hash_and_nullifier(
        contract_address: AztecAddress,
        nonce: Field,
        storage_slot: Field,
        serialized_note: [Field; PUBLIC_KEY_NOTE_LEN]
    ) -> pub [Field; 4] {
        assert(storage_slot == 1);
        let note_header = NoteHeader::new(contract_address, nonce, storage_slot);
        note_utils::compute_note_hash_and_nullifier(PublicKeyNoteMethods, note_header, serialized_note)
    }
}

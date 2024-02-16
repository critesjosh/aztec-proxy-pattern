mod interfaces;
mod LogicContract;

contract Proxy {
    use dep::safe_math::SafeU120;

    use dep::aztec::{
        protocol_types::{abis::function_selector::FunctionSelector, address::AztecAddress},
        note::{note_getter_options::NoteGetterOptions, note_header::NoteHeader, utils as note_utils},
        context::{PrivateContext, Context},
        state_vars::{map::Map, public_state::PublicState, immutable_singleton::ImmutableSingleton, singleton::Singleton}
    };
    use dep::field_note::field_note::{FieldNote};
    use crate::interfaces::SlowMap;
    use crate::LogicContract::{LogicContractPrivateContextInterface, LogicContractPublicContextInterface};

    struct Storage {
        admin: PublicState<AztecAddress>, // admin can end vote
        slow_update: ImmutableSingleton<FieldNote>,
        public_slow_update: PublicState<AztecAddress>,
        public_counter: PublicState<SafeU120>,
        counter: Singleton<FieldNote>,
    }

    #[aztec(private)] 
    fn constructor(admin: AztecAddress, slow_updates_contract: AztecAddress) {
        let mut slow_note = FieldNote::new(slow_updates_contract.to_field());
        storage.slow_update.initialize(&mut slow_note, false);

        context.call_public_function(
            context.this_address(),
            FunctionSelector::from_signature("_initialize((Field),(Field))"),
            [admin.to_field(), slow_updates_contract.to_field()]
        );
    }

    #[aztec(public)]
    internal fn _initialize(admin: AztecAddress, slow_updates_contract: AztecAddress) {
        assert(admin.to_field() != 0, "invalid admin");
        storage.admin.write(admin);
        storage.public_slow_update.write(slow_updates_contract);
        SlowMap::at(slow_updates_contract).initialize(context);
    }

    #[aztec(private)]
    fn init_slow_tree(logic_contract: AztecAddress) {
        let slow = SlowMap::at(AztecAddress::from_field(storage.slow_update.get_note().value));
        slow.update_at_private(&mut context, 0, logic_contract.to_field());
        context.call_public_function(
            context.this_address(),
            FunctionSelector::from_signature("_init_slow_tree((Field))"),
            [context.msg_sender().to_field()]
        );
    }

    #[aztec(public)]
    internal fn _init_slow_tree(caller: AztecAddress) {
        assert(storage.admin.read().eq(caller), "caller is not admin");
    }

    #[aztec(private)]
    fn call_counter() {
        let slow = SlowMap::at(AztecAddress::from_field(storage.slow_update.get_note().value));
        let logic_contract = LogicContractPrivateContextInterface::at(AztecAddress::from_field(slow.read_at(&mut context, 0)));
        let old_count = storage.counter.get_note(true).value;
        let new_count = logic_contract.increment_counter(&mut context, old_count)[0];
        storage.counter.replace(&mut FieldNote::new(new_count), true);
    }

    #[aztec(public)]
    fn call_public_counter() {
        let slow = SlowMap::at(AztecAddress::from_field(storage.slow_update.get_note().value));
        let logic_contract = LogicContractPublicContextInterface::at(AztecAddress::from_field(slow.read_at_pub(context, 0)));
        let old_count = storage.public_counter.read().value;
        let new_count = logic_contract.increment_public_counter(context, old_count)[0];
        storage.public_counter.write(SafeU120::new(new_count));
    }

    unconstrained fn get_admin() -> pub AztecAddress {
        storage.admin.read()
    }

    unconstrained fn is_slow_tree_init() -> pub bool {
        storage.slow_update.is_initialized()
    }

    unconstrained fn get_slow_update() -> pub Field {
        storage.slow_update.view_note().value
    }

    unconstrained fn get_count() -> pub Field {
        storage.counter.view_note().value
    }

    unconstrained fn compute_note_hash_and_nullifier(
        contract_address: AztecAddress,
        nonce: Field,
        storage_slot: Field,
        note_type_id: Field,
        serialized_note: [Field; 1]
    ) -> pub [Field; 4] {
        let note_header = NoteHeader::new(contract_address, nonce, storage_slot);
        note_utils::compute_note_hash_and_nullifier(FieldNote::deserialize_content, note_header, serialized_note)
    }
}

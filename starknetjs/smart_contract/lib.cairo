// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts for Cairo ^0.20.0

use starknet::ContractAddress;

#[starknet::interface]
pub trait ILabels<TContractState> {
    fn get_token_uri(self: @TContractState, token_id: u256) -> ByteArray;
    fn set_token_uri(ref self: TContractState, token_id: u256, uri: ByteArray); 
    fn mint_item(ref self: TContractState, recipient: ContractAddress, uri: ByteArray);
}

#[starknet::contract]
mod Labels {
    use openzeppelin::introspection::src5::SRC5Component;
    use openzeppelin::token::erc721::ERC721Component;
    use starknet::ContractAddress;
    use openzeppelin::token::erc721::extensions::ERC721EnumerableComponent;
	use starknet::storage::{StoragePointerReadAccess, StoragePointerWriteAccess};
	use starknet::storage::{Map, StorageMapReadAccess, StorageMapWriteAccess};

    component!(path: ERC721Component, storage: erc721, event: ERC721Event);
    component!(path: SRC5Component, storage: src5, event: SRC5Event);
    component!(path: ERC721EnumerableComponent, storage: erc721_enumerable, event: ERC721EnumerableEvent);
	

    // External
    #[abi(embed_v0)]
    impl ERC721MixinImpl = ERC721Component::ERC721MixinImpl<ContractState>;
    #[abi(embed_v0)]
    impl ERC721EnumerableImpl = ERC721EnumerableComponent::ERC721EnumerableImpl<ContractState>;

    // Internal
    impl ERC721InternalImpl = ERC721Component::InternalImpl<ContractState>;
    impl ERC721EnumerableInternalImpl = ERC721EnumerableComponent::InternalImpl<ContractState>;

    #[storage]
    struct Storage {
        #[substorage(v0)]
        erc721: ERC721Component::Storage,
        #[substorage(v0)]
        src5: SRC5Component::Storage,
        #[substorage(v0)]
        erc721_enumerable: ERC721EnumerableComponent::Storage,
		pub counter: u256,
		pub token_uris: Map<u256, ByteArray>,
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        #[flat]
        ERC721Event: ERC721Component::Event,
        #[flat]
        SRC5Event: SRC5Component::Event,
        #[flat]
        ERC721EnumerableEvent: ERC721EnumerableComponent::Event,
    }

    #[constructor]
    fn constructor(ref self: ContractState) {
        self.erc721.initializer("Labels", "LBL", "");
        self.erc721_enumerable.initializer();
    }

    impl ERC721HooksImpl of ERC721Component::ERC721HooksTrait<ContractState> {
        fn before_update(
            ref self: ERC721Component::ComponentState<ContractState>,
            to: ContractAddress,
            token_id: u256,
            auth: ContractAddress,
        ) {
            let mut contract_state = self.get_contract_mut();
            contract_state.erc721_enumerable.before_update(to, token_id);
        }
    }

    #[generate_trait]
    #[abi(per_item)]
    impl ExternalImpl of ExternalTrait {
        #[external(v0)]
        fn safe_mint(
            ref self: ContractState,
            recipient: ContractAddress,
            token_id: u256,
            data: Span<felt252>,
        ) {
            self.erc721.safe_mint(recipient, token_id, data);
        }

        #[external(v0)]
        fn safeMint(
            ref self: ContractState,
            recipient: ContractAddress,
            tokenId: u256,
            data: Span<felt252>,
        ) {
            self.safe_mint(recipient, tokenId, data);
        }
	}

    #[abi(embed_v0)]
    impl ImplLabels of super::ILabels<ContractState> {
        fn get_token_uri(self: @ContractState, token_id: u256) -> ByteArray {
            assert(self.erc721.exists(token_id), ERC721Component::Errors::INVALID_TOKEN_ID);
            return self.token_uris.read(token_id);
        }

        fn set_token_uri(ref self: ContractState, token_id: u256, uri: ByteArray) {
            assert(self.erc721.exists(token_id), ERC721Component::Errors::INVALID_TOKEN_ID);
            self.token_uris.write(token_id, uri);
        }

    
        fn mint_item(ref self: ContractState, recipient: ContractAddress, uri: ByteArray) {
            let current_counter = self.counter.read();
            let new_counter = current_counter + 1;
            self.counter.write(new_counter);

            self.erc721.mint(recipient, new_counter);
            self.set_token_uri(new_counter, uri);
        }
    }
}
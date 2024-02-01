
/* Autogenerated file, do not edit! */

/* eslint-disable */
import {
  AztecAddress,
  AztecAddressLike,
  CompleteAddress,
  Contract,
  ContractArtifact,
  ContractBase,
  ContractFunctionInteraction,
  ContractMethod,
  DeployMethod,
  EthAddress,
  EthAddressLike,
  FieldLike,
  Fr,
  FunctionSelectorLike,
  loadContractArtifact,
  NoirCompiledContract,
  Point,
  PublicKey,
  Wallet,
} from '@aztec/aztec.js';
import ProxyContractArtifactJson from '../proxy/target/proxy-Proxy.json' assert { type: 'json' };
export const ProxyContractArtifact = loadContractArtifact(ProxyContractArtifactJson as NoirCompiledContract);

/**
 * Type-safe interface for contract Proxy;
 */
export class ProxyContract extends ContractBase {
  
  private constructor(
    completeAddress: CompleteAddress,
    wallet: Wallet,
    portalContract = EthAddress.ZERO
  ) {
    super(completeAddress, ProxyContractArtifact, wallet, portalContract);
  }
  

  
  /**
   * Creates a contract instance.
   * @param address - The deployed contract's address.
   * @param wallet - The wallet to use when interacting with the contract.
   * @returns A promise that resolves to a new Contract instance.
   */
  public static async at(
    address: AztecAddress,
    wallet: Wallet,
  ) {
    return Contract.at(address, ProxyContract.artifact, wallet) as Promise<ProxyContract>;
  }

  
  /**
   * Creates a tx to deploy a new instance of this contract.
   */
  public static deploy(wallet: Wallet, admin: AztecAddressLike, slow_updates_contract: AztecAddressLike, logic_contract: AztecAddressLike) {
    return new DeployMethod<ProxyContract>(Point.ZERO, wallet, ProxyContractArtifact, ProxyContract.at, Array.from(arguments).slice(1));
  }

  /**
   * Creates a tx to deploy a new instance of this contract using the specified public key to derive the address.
   */
  public static deployWithPublicKey(publicKey: PublicKey, wallet: Wallet, admin: AztecAddressLike, slow_updates_contract: AztecAddressLike, logic_contract: AztecAddressLike) {
    return new DeployMethod<ProxyContract>(publicKey, wallet, ProxyContractArtifact, ProxyContract.at, Array.from(arguments).slice(2));
  }
  

  
  /**
   * Returns this contract's artifact.
   */
  public static get artifact(): ContractArtifact {
    return ProxyContractArtifact;
  }
  

  /** Type-safe wrappers for the public methods exposed by the contract. */
  public methods!: {
    
    /** compute_note_hash_and_nullifier(contract_address: struct, nonce: field, storage_slot: field, serialized_note: array) */
    compute_note_hash_and_nullifier: ((contract_address: AztecAddressLike, nonce: FieldLike, storage_slot: FieldLike, serialized_note: FieldLike[]) => ContractFunctionInteraction) & Pick<ContractMethod, 'selector'>;

    /** get_slow_update() */
    get_slow_update: (() => ContractFunctionInteraction) & Pick<ContractMethod, 'selector'>;

    /** call_counter() */
    call_counter: (() => ContractFunctionInteraction) & Pick<ContractMethod, 'selector'>;

    /** call_public_counter() */
    call_public_counter: (() => ContractFunctionInteraction) & Pick<ContractMethod, 'selector'>;

    /** init_slow_tree(logic_contract: struct) */
    init_slow_tree: ((logic_contract: AztecAddressLike) => ContractFunctionInteraction) & Pick<ContractMethod, 'selector'>;
  };
}

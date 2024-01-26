use debug::PrintTrait;
use erc4626::erc4626::{IERC4626Dispatcher, IERC4626DispatcherTrait};
use erc4626::utils::{pow_256};
use integer::BoundedU256;
use openzeppelin::token::erc20::{ERC20ABIDispatcher, ERC20ABIDispatcherTrait};
use snforge_std::{
    declare, ContractClassTrait, start_prank, stop_prank, CheatTarget, start_warp, stop_warp
};
use starknet::{ContractAddress, contract_address_const, get_contract_address};

fn OWNER() -> ContractAddress {
    'owner'.try_into().unwrap()
}

fn TOKEN_ADDRESS() -> ContractAddress {
    'token_address'.try_into().unwrap()
}

fn VAULT_ADDRESS() -> ContractAddress {
    'vault_address'.try_into().unwrap()
}

fn deploy_token() -> (ERC20ABIDispatcher, ContractAddress) {
    let token = declare('ERC20Token');
    let mut calldata = Default::default();
    Serde::serialize(@OWNER(), ref calldata);

    let address = token.deploy_at(@calldata, TOKEN_ADDRESS()).unwrap();
    let dispatcher = ERC20ABIDispatcher { contract_address: address, };
    (dispatcher, address)
}

fn deploy_contract() -> (ERC20ABIDispatcher, IERC4626Dispatcher) {
    let (token, token_address) = deploy_token();
    let mut params = ArrayTrait::<felt252>::new();
    token_address.serialize(ref params);
    params.append('Vault Mock Token');
    params.append('vltMCK');
    params.append(8);
    let vault = declare('ERC4626');
    let contract_address = vault.deploy_at(@params, VAULT_ADDRESS()).unwrap();
    (token, IERC4626Dispatcher { contract_address })
}


#[test]
fn test_constructor() {
    let (asset, vault) = deploy_contract();
    assert(vault.asset() == asset.contract_address, 'invalid asset');
    assert(vault.decimals() == (18 + 8), 'invalid decimals');
    assert(vault.name() == 'Vault Mock Token', 'invalid name');
    assert(vault.symbol() == 'vltMCK', 'invalid symbol');
}
#[test]
fn convert_to_assets() {
    let (asset, vault) = deploy_contract();
    let shares = pow_256(10, 10);
    // 10e10 * (0 + 1) / (0 + 10e8)
    assert(vault.convert_to_assets(shares) == 100, 'invalid assets');
}
#[test]
fn convert_to_shares() {
    let (asset, vault) = deploy_contract();
    let assets = 10;
    // asset * shares / total assets
    // 10 * (0 + 10e8) / (0 + 1)
    assert(vault.convert_to_shares(assets) == pow_256(10, 9), 'invalid shares');
}

#[test]
fn max_deposit() {
    let (asset, vault) = deploy_contract();
    assert(vault.max_deposit(get_contract_address()) == BoundedU256::max(), 'invalid max deposit');
}

#[test]
fn max_mint() {
    let (asset, vault) = deploy_contract();
    assert(vault.max_mint(get_contract_address()) == BoundedU256::max(), 'invalid max mint');
}

#[test]
fn preview_deposit() {
    let (asset, vault) = deploy_contract();
    assert(vault.preview_deposit(10) == pow_256(10, 9), 'invalid preview_deposit');
}

#[test]
fn preview_mint() {
    let (asset, vault) = deploy_contract();
    assert(vault.preview_mint(pow_256(10, 10)) == 100, 'invalid preview_mint');
}

#[test]
fn preview_redeem() {
    let (asset, vault) = deploy_contract();
    assert(vault.preview_redeem(pow_256(10, 10)) == 100, 'invalid preview_redeem');
}

#[test]
fn preview_withdraw() {
    let (asset, vault) = deploy_contract();
    assert(vault.preview_redeem(pow_256(10, 10)) == 100, 'invalid preview_withdraw');
}
// #[test]
// fn deposit() {
//     let (asset, dispatcher, vault) = deploy_contract();
//     let owner = contract_address_const::<0x42>();
//     let erc20dispatcher = ERC20ABIDispatcher { contract_address: asset };
//     let amount = erc20dispatcher.balance_of(get_contract_address());
//     erc20dispatcher.transfer(owner, amount);
//     start_prank(asset, owner);
//     erc20dispatcher.approve(vault, BoundedU256::max());
//     stop_prank(asset);
//     start_prank(vault, owner);
//     assert(dispatcher.deposit(amount, owner) == amount, 'invalid shares');
//     assert(dispatcher.balance_of(owner) == amount, 'invalid balance');
// }
// #[test]
// fn max_redeem() {
//     let (asset, dispatcher, vault) = deploy_contract();
//     assert(dispatcher.max_redeem(get_contract_address()) == 0, 'invalid initial max redeem');
//     let owner = contract_address_const::<0x42>();
//     let erc20dispatcher = ERC20ABIDispatcher { contract_address: asset };
//     let amount = erc20dispatcher.balance_of(get_contract_address());
//     erc20dispatcher.transfer(owner, amount);
//     start_prank(asset, owner);
//     erc20dispatcher.approve(vault, BoundedU256::max());
//     stop_prank(asset);
//     start_prank(vault, owner);
//     dispatcher.deposit(amount, owner);
//     assert(dispatcher.max_redeem(owner) == amount, 'invalid max redeem');
// }

// #[test]
// fn max_withdraw() {
//     let (asset, dispatcher, vault) = deploy_contract();
//     assert(dispatcher.max_withdraw(get_contract_address()) == 0, 'invalid initial max withdraw');
//     let owner = contract_address_const::<0x42>();
//     let erc20dispatcher = ERC20ABIDispatcher { contract_address: asset };
//     let amount = erc20dispatcher.balance_of(get_contract_address());
//     erc20dispatcher.transfer(owner, amount);
//     start_prank(asset, owner);
//     erc20dispatcher.approve(vault, BoundedU256::max());
//     stop_prank(asset);
//     start_prank(vault, owner);
//     dispatcher.deposit(amount, owner);
//     assert(dispatcher.max_withdraw(owner) == amount, 'invalid max withdraw');
// }

// #[test]
// fn mint() {
//     let (asset, dispatcher, vault) = deploy_contract();
//     let owner = contract_address_const::<0x42>();
//     let erc20dispatcher = ERC20ABIDispatcher { contract_address: asset };
//     let amount = erc20dispatcher.balance_of(get_contract_address());
//     erc20dispatcher.transfer(owner, amount);
//     start_prank(asset, owner);
//     erc20dispatcher.approve(vault, BoundedU256::max());
//     stop_prank(asset);
//     start_prank(vault, owner);
//     assert(dispatcher.mint(amount, owner) == amount, 'invalid assets');
//     assert(dispatcher.balance_of(owner) == amount, 'invalid balance');
// }

// #[test]
// fn redeem() {
//     let (asset, dispatcher, vault) = deploy_contract();
//     let owner = contract_address_const::<0x42>();
//     let erc20dispatcher = ERC20ABIDispatcher { contract_address: asset };
//     let amount = erc20dispatcher.balance_of(get_contract_address());
//     erc20dispatcher.transfer(owner, amount);
//     start_prank(asset, owner);
//     erc20dispatcher.approve(vault, BoundedU256::max());
//     stop_prank(asset);
//     start_prank(vault, owner);
//     dispatcher.deposit(amount, owner);
//     assert(dispatcher.balance_of(owner) == amount, 'invalid balance');
//     assert(dispatcher.redeem(amount, owner, owner) == amount, 'invalid assets');
//     assert(dispatcher.balance_of(owner) == 0, 'invalid final balance');
// }

// #[test]
// fn withdraw() {
//     let (asset, dispatcher, vault) = deploy_contract();
//     let owner = contract_address_const::<0x42>();
//     let erc20dispatcher = ERC20ABIDispatcher { contract_address: asset };
//     let amount = erc20dispatcher.balance_of(get_contract_address());
//     erc20dispatcher.transfer(owner, amount);
//     start_prank(asset, owner);
//     erc20dispatcher.approve(vault, BoundedU256::max());
//     stop_prank(asset);
//     start_prank(vault, owner);
//     dispatcher.deposit(amount, owner);
//     assert(dispatcher.balance_of(owner) == amount, 'invalid balance');
//     assert(dispatcher.withdraw(amount, owner, owner) == amount, 'invalid shares');
//     assert(dispatcher.balance_of(owner) == 0, 'invalid final balance');
// }



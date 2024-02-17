package bank_test

import (
	"fmt"
	"math/big"
	"testing"

	sdk "github.com/cosmos/cosmos-sdk/types"
	"github.com/ethereum/go-ethereum/common"
	"github.com/ethereum/go-ethereum/core/vm"
	"github.com/sei-protocol/sei-chain/precompiles/bank"
	testkeeper "github.com/sei-protocol/sei-chain/testutil/keeper"
	"github.com/sei-protocol/sei-chain/x/evm/state"
	"github.com/sei-protocol/sei-chain/x/evm/types"
	"github.com/stretchr/testify/require"
)

func TestRun(t *testing.T) {
	k, ctx := testkeeper.MockEVMKeeper()

	mnemonic1 := "two forward crumble gaze tunnel economy tuna various hungry prevent furnace stairs nature blush blossom win laundry agent quantum outer regret also pen cage"
	senderSeiAddr, senderEvmAddr := testkeeper.MockAddressPairUsingMnemonic(mnemonic1)
	k.SetAddressMapping(ctx, senderSeiAddr, senderEvmAddr)
	bankKeeper := k.BankKeeper()
	err := bankKeeper.MintCoins(ctx, types.ModuleName, sdk.NewCoins(sdk.NewCoin("usei", sdk.NewInt(10000))))
	require.Nil(t, err)
	err = bankKeeper.SendCoinsFromModuleToAccount(ctx, types.ModuleName, senderSeiAddr, sdk.NewCoins(sdk.NewCoin("usei", sdk.NewInt(10000))))
	require.Nil(t, err)

	mnemonic2 := "depend ring history coil transfer venture brisk betray brain trigger canal genius method describe figure pepper good buffalo sick cage ethics resemble law aim"
	receiverSeiAddr, receiverEvmAddr := testkeeper.MockAddressPairUsingMnemonic(mnemonic2)
	k.SetAddressMapping(ctx, receiverSeiAddr, receiverEvmAddr)
	p, err := bank.NewPrecompile(bankKeeper, k)
	require.Nil(t, err)
	statedb := state.NewDBImpl(ctx, k, true)
	evm := vm.EVM{
		StateDB:   statedb,
		TxContext: vm.TxContext{Origin: senderEvmAddr},
	}

	fmt.Println("STARTING BANK SENDS / PRECOMPILE SENDS ----------------------- ")

	passTestOrdering := false
	var bal *big.Int
	if passTestOrdering {
		////////// bank keeper -- send coins [START]
		fmt.Println("TEST - sending 5000 coins from bank keeper")
		err = bankKeeper.SendCoins(ctx, senderSeiAddr, receiverSeiAddr, sdk.NewCoins(sdk.NewCoin("usei", sdk.NewInt(5000))))
		require.Nil(t, err)
		////////// bank keeper -- send coins [END]

		////////// precompile -- send coins [START]
		fmt.Println("TEST - sending 10 coins from precompile")
		sendNative, err := p.ABI.MethodById(p.SendNativeID)
		require.Nil(t, err)
		argsNative, err := sendNative.Inputs.Pack(receiverSeiAddr.String(), big.NewInt(10_000_000_000_000))
		require.Nil(t, err)
		_, err = p.Run(&evm, senderEvmAddr, append(p.SendNativeID, argsNative...))
		require.Nil(t, err)
		////////// precompile -- send coins [END]
	} else {
		////////// precompile -- send coins [START]
		fmt.Println("TEST - sending 10 coins from precompile")
		sendNative, err := p.ABI.MethodById(p.SendNativeID)
		require.Nil(t, err)
		argsNative, err := sendNative.Inputs.Pack(receiverSeiAddr.String(), big.NewInt(10_000_000_000_000))
		require.Nil(t, err)
		_, err = p.Run(&evm, senderEvmAddr, append(p.SendNativeID, argsNative...))
		require.Nil(t, err)
		////////// precompile -- send coins [END]

		////////// bank keeper -- send coins [START]
		fmt.Println("TEST - sending 5000 coins from bank keeper")
		err = bankKeeper.SendCoins(ctx, senderSeiAddr, receiverSeiAddr, sdk.NewCoins(sdk.NewCoin("usei", sdk.NewInt(5000))))
		require.Nil(t, err)
		////////// bank keeper -- send coins [END]
	}
	fmt.Printf("TEST - sender senderAddrString %+v senderEVMAddr %+v \n", senderSeiAddr.String(), senderEvmAddr)
	fmt.Printf("TEST - receiver seiAddrString %+v evmAddr %+v\n", receiverSeiAddr.String(), receiverEvmAddr)

	///////// Check balance using bank [START]
	// bankKeeper.Balance(ctx, types.QueryBalanceRequest{Address: senderSeiAddr.String()})
	///////// Check balance using bank [END]

	///////// Check balance on ETH address [START]
	bal = statedb.GetBalance(receiverEvmAddr)
	fmt.Println("Balance: ", bal)
	require.Equal(t, big.NewInt(5010000000000000), bal)
	///////// Check balance on ETH address [END]

	///////// Check balance using precompile [START]
	balance, err := p.ABI.MethodById(p.BalanceID)
	require.Nil(t, err)
	args, err := balance.Inputs.Pack(receiverEvmAddr, "usei")
	require.Nil(t, err)
	res, err := p.Run(&evm, common.Address{}, append(p.BalanceID, args...))
	require.Nil(t, err)
	is, err := balance.Outputs.Unpack(res)
	require.Nil(t, err)
	require.Equal(t, 1, len(is))
	require.Equal(t, big.NewInt(5010), is[0].(*big.Int))
	///////// Check balance using precompile [END]

	panic("TEST SUCCEEEDED")
}

// func TestMetadata(t *testing.T) {
// 	k, ctx := testkeeper.MockEVMKeeper()
// 	bankKeeper.SetDenomMetaData(ctx, banktypes.Metadata{Name: "SEI", Symbol: "usei", Base: "usei"})
// 	p, err := bank.NewPrecompile(bankKeeper, k)
// 	require.Nil(t, err)
// 	statedb := state.NewDBImpl(ctx, k, true)
// 	evm := vm.EVM{
// 		StateDB: statedb,
// 	}
// 	name, err := p.ABI.MethodById(p.NameID)
// 	require.Nil(t, err)
// 	args, err := name.Inputs.Pack("usei")
// 	require.Nil(t, err)
// 	res, err := p.Run(&evm, common.Address{}, append(p.NameID, args...))
// 	require.Nil(t, err)
// 	outputs, err := name.Outputs.Unpack(res)
// 	require.Nil(t, err)
// 	require.Equal(t, "SEI", outputs[0])

// 	symbol, err := p.ABI.MethodById(p.SymbolID)
// 	require.Nil(t, err)
// 	args, err = symbol.Inputs.Pack("usei")
// 	require.Nil(t, err)
// 	res, err = p.Run(&evm, common.Address{}, append(p.SymbolID, args...))
// 	require.Nil(t, err)
// 	outputs, err = symbol.Outputs.Unpack(res)
// 	require.Nil(t, err)
// 	require.Equal(t, "usei", outputs[0])

// 	decimal, err := p.ABI.MethodById(p.DecimalsID)
// 	require.Nil(t, err)
// 	args, err = decimal.Inputs.Pack("usei")
// 	require.Nil(t, err)
// 	res, err = p.Run(&evm, common.Address{}, append(p.DecimalsID, args...))
// 	require.Nil(t, err)
// 	outputs, err = decimal.Outputs.Unpack(res)
// 	require.Nil(t, err)
// 	require.Equal(t, uint8(0), outputs[0])

// 	supply, err := p.ABI.MethodById(p.SupplyID)
// 	require.Nil(t, err)
// 	args, err = supply.Inputs.Pack("usei")
// 	require.Nil(t, err)
// 	res, err = p.Run(&evm, common.Address{}, append(p.SupplyID, args...))
// 	require.Nil(t, err)
// 	outputs, err = supply.Outputs.Unpack(res)
// 	require.Nil(t, err)
// 	require.Equal(t, big.NewInt(10), outputs[0])
// }

// func TestRequiredGas(t *testing.T) {
// 	k, _ := testkeeper.MockEVMKeeper()
// 	p, err := bank.NewPrecompile(bankKeeper, k)
// 	require.Nil(t, err)
// 	balanceRequiredGas := p.RequiredGas(p.BalanceID)
// 	require.Equal(t, uint64(1000), balanceRequiredGas)
// 	// invalid method
// 	require.Equal(t, uint64(0), p.RequiredGas([]byte{1, 1, 1, 1}))
// }

// func TestAddress(t *testing.T) {
// 	k, _ := testkeeper.MockEVMKeeper()
// 	p, err := bank.NewPrecompile(bankKeeper, k)
// 	require.Nil(t, err)
// 	require.Equal(t, common.HexToAddress(bank.BankAddress), p.Address())
// }

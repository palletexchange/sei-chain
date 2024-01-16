package json

import (
	"bytes"
	"embed"
	gjson "encoding/json"
	"fmt"
	"math/big"
	"strings"

	sdk "github.com/cosmos/cosmos-sdk/types"
	"github.com/ethereum/go-ethereum/accounts/abi"
	"github.com/ethereum/go-ethereum/common"
	"github.com/ethereum/go-ethereum/core/vm"
	pcommon "github.com/sei-protocol/sei-chain/precompiles/common"
	"github.com/sei-protocol/sei-chain/utils"
)

const (
	ExtractAsBytesMethod     = "extractAsBytes"
	ExtractAsBytesListMethod = "extractAsBytesList"
	ExtractAsUint256Method   = "extractAsUint256"
)

const JSONAddress = "0x0000000000000000000000000000000000001003"
const GasCostPerByte = 100 // TODO: parameterize

var _ vm.PrecompiledContract = &Precompile{}

// Embed abi json file to the executable binary. Needed when importing as dependency.
//
//go:embed abi.json
var f embed.FS

type Precompile struct {
	pcommon.Precompile
	address common.Address

	ExtractAsBytesID     []byte
	ExtractAsBytesListID []byte
	ExtractAsUint256ID   []byte
}

func NewPrecompile() (*Precompile, error) {
	abiBz, err := f.ReadFile("abi.json")
	if err != nil {
		return nil, fmt.Errorf("error loading the staking ABI %s", err)
	}

	newAbi, err := abi.JSON(bytes.NewReader(abiBz))
	if err != nil {
		return nil, err
	}

	p := &Precompile{
		Precompile: pcommon.Precompile{ABI: newAbi},
		address:    common.HexToAddress(JSONAddress),
	}

	for name, m := range newAbi.Methods {
		switch name {
		case ExtractAsBytesMethod:
			p.ExtractAsBytesID = m.ID
		case ExtractAsBytesListMethod:
			p.ExtractAsBytesListID = m.ID
		case ExtractAsUint256Method:
			p.ExtractAsUint256ID = m.ID
		}
	}

	return p, nil
}

// RequiredGas returns the required bare minimum gas to execute the precompile.
func (p Precompile) RequiredGas(input []byte) uint64 {
	return uint64(GasCostPerByte * (len(input) - 4))
}

func (Precompile) IsTransaction(string) bool {
	return false
}

func (p Precompile) Address() common.Address {
	return p.address
}

func (p Precompile) Run(evm *vm.EVM, _ common.Address, input []byte) (bz []byte, err error) {
	ctx, method, args, err := p.Prepare(evm, input)
	if err != nil {
		return nil, err
	}

	switch method.Name {
	case ExtractAsBytesMethod:
		return p.extractAsBytes(ctx, method, args)
	case ExtractAsBytesListMethod:
		return p.extractAsBytesList(ctx, method, args)
	case ExtractAsUint256Method:
		byteArr := make([]byte, 32)
		uint_, err := p.ExtractAsUint256(ctx, method, args)
		if err != nil {
			return nil, err
		}
		uint_.FillBytes(byteArr)
		return byteArr, nil
	}
	return
}

func (p Precompile) extractAsBytes(_ sdk.Context, method *abi.Method, args []interface{}) ([]byte, error) {
	pcommon.AssertArgsLength(args, 2)

	// type assertion will always succeed because it's already validated in p.Prepare call in Run()
	bz := args[0].([]byte)
	decoded := map[string]gjson.RawMessage{}
	if err := gjson.Unmarshal(bz, &decoded); err != nil {
		return nil, err
	}
	key := args[1].(string)
	result, ok := decoded[key]
	if !ok {
		return nil, fmt.Errorf("input does not contain key %s", key)
	}

	return method.Outputs.Pack([]byte(result))
}

func (p Precompile) extractAsBytesList(_ sdk.Context, method *abi.Method, args []interface{}) ([]byte, error) {
	pcommon.AssertArgsLength(args, 2)

	// type assertion will always succeed because it's already validated in p.Prepare call in Run()
	bz := args[0].([]byte)
	decoded := map[string][]gjson.RawMessage{}
	if err := gjson.Unmarshal(bz, &decoded); err != nil {
		return nil, err
	}
	key := args[1].(string)
	result, ok := decoded[key]
	if !ok {
		return nil, fmt.Errorf("input does not contain key %s", key)
	}

	return method.Outputs.Pack(utils.Map(result, func(r gjson.RawMessage) []byte { return []byte(r) }))
}

func (p Precompile) ExtractAsUint256(_ sdk.Context, _ *abi.Method, args []interface{}) (*big.Int, error) {
	pcommon.AssertArgsLength(args, 2)

	// type assertion will always succeed because it's already validated in p.Prepare call in Run()
	bz := args[0].([]byte)
	decoded := map[string]gjson.RawMessage{}
	if err := gjson.Unmarshal(bz, &decoded); err != nil {
		return nil, err
	}
	key := args[1].(string)
	result, ok := decoded[key]
	if !ok {
		return nil, fmt.Errorf("input does not contain key %s", key)
	}

	// Assuming result is your byte slice
	// Convert byte slice to string and trim quotation marks
	strValue := strings.Trim(string(result), "\"")

	// Convert the string to big.Int
	value, success := new(big.Int).SetString(strValue, 10)
	if !success {
		return nil, fmt.Errorf("failed to convert %s to big.Int", strValue)
	}

	return value, nil
}
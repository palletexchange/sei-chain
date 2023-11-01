package keeper

import (
	"encoding/binary"

	sdk "github.com/cosmos/cosmos-sdk/types"
	"github.com/ethereum/go-ethereum/common"
	"github.com/ethereum/go-ethereum/crypto"
	"github.com/sei-protocol/sei-chain/x/evm/types"
)

func (k *Keeper) GetCode(ctx sdk.Context, addr common.Address) []byte {
	return k.PrefixStore(ctx, types.CodeKeyPrefix).Get(addr[:])
}

func (k *Keeper) SetCode(ctx sdk.Context, addr common.Address, code []byte) {
	k.PrefixStore(ctx, types.CodeKeyPrefix).Set(addr[:], code)
	length := make([]byte, 8)
	binary.BigEndian.PutUint64(length, uint64(len(code)))
	k.PrefixStore(ctx, types.CodeSizeKeyPrefix).Set(addr[:], length)
	h := crypto.Keccak256Hash(code)
	k.PrefixStore(ctx, types.CodeHashKeyPrefix).Set(addr[:], h[:])
}

func (k *Keeper) GetCodeHash(ctx sdk.Context, addr common.Address) common.Hash {
	store := k.PrefixStore(ctx, types.CodeHashKeyPrefix)
	bz := store.Get(addr[:])
	if bz == nil {
		return common.Hash{}
	}
	return common.BytesToHash(bz)
}

func (k *Keeper) GetCodeSize(ctx sdk.Context, addr common.Address) int {
	bz := k.PrefixStore(ctx, types.CodeSizeKeyPrefix).Get(addr[:])
	if bz == nil {
		return 0
	}
	return int(binary.BigEndian.Uint64(bz))
}
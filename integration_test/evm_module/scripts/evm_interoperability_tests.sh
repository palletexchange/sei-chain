cd contracts
npm ci
npx hardhat test --network seilocal test/CW20toERC20PointerTest.js
npx hardhat test --network seilocal test/ERC20toCW20PointerTest.js
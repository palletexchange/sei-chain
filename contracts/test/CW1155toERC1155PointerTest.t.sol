// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {Test, console2} from "forge-std/Test.sol";
import {CW1155ERC1155Pointer} from "../src/CW1155ERC1155Pointer.sol";
import {IWasmd} from "../src/precompiles/IWasmd.sol";
import {IJson} from "../src/precompiles/IJson.sol";
import {IAddr} from "../src/precompiles/IAddr.sol";
import "@openzeppelin/contracts/interfaces/draft-IERC6093.sol";

address constant WASMD_PRECOMPILE_ADDRESS = 0x0000000000000000000000000000000000001002;
address constant JSON_PRECOMPILE_ADDRESS = 0x0000000000000000000000000000000000001003;
address constant ADDR_PRECOMPILE_ADDRESS = 0x0000000000000000000000000000000000001004;

address constant MockCallerEVMAddr = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;
address constant MockOperatorEVMAddr = 0xF39fD6e51Aad88F6f4CE6AB8827279CFffb92267;
address constant MockZeroAddress = 0x0000000000000000000000000000000000000000;

string constant MockCallerSeiAddr = "sei19zhelek4q5lt4zam8mcarmgv92vzgqd3ux32jw";
string constant MockOperatorSeiAddr = "sei1vldxw5dy5k68hqr4d744rpg9w8cqs54x4asdqe";
string constant MockCWContractAddress = "sei14hj2tavq8fpesdwxxcu44rty3hh90vhujrvcmstl4zr3txmfvw9sh9m79m";

contract MockWasmd is IWasmd {

    // Transactions
    function instantiate(
        uint64,
        string memory,
        bytes memory,
        string memory,
        bytes memory
    ) external pure returns (string memory, bytes memory) {
        return (MockCWContractAddress, bytes(""));
    }

    function execute(
        string memory contractAddress,
        bytes memory,
        bytes memory
    ) external pure returns (bytes memory) {
        require(keccak256(abi.encodePacked(contractAddress)) == keccak256(abi.encodePacked(MockCWContractAddress)), "wrong CW contract address");
        return bytes("");
    }

    // Queries
    function query(string memory, bytes memory) external pure returns (bytes memory) {
        return bytes("");
    }
}

contract MockJson is IJson {
    function extractAsBytes(bytes memory, string memory) external pure returns (bytes memory) {
        return bytes("extracted bytes");
    }

    function extractAsBytesList(bytes memory, string memory) external pure returns (bytes[] memory) {
        return new bytes[](0);
    }

    function extractAsUint256(bytes memory input, string memory key) external view returns (uint256 response) {
        return 0;
    }
}

contract MockAddr is IAddr {
    function getSeiAddr(address addr) external pure returns (string memory) {
        if (addr == MockCallerEVMAddr) {
            return MockCallerSeiAddr;
        }
        return MockOperatorSeiAddr;
    }

    function getEvmAddr(string memory addr) external pure returns (address) {
        if (keccak256(abi.encodePacked(addr)) == keccak256(abi.encodePacked(MockCallerSeiAddr))) {
            return MockCallerEVMAddr;
        }
        return MockOperatorEVMAddr;
    }
}

contract CW1155ERC1155PointerTest is Test {
    CW1155ERC1155Pointer pointer;
    MockWasmd mockWasmd;
    MockJson mockJson;
    MockAddr mockAddr;

    function setUp() public {
        pointer = new CW1155ERC1155Pointer(MockCWContractAddress, "ipfs://uri.json");
        mockWasmd = new MockWasmd();
        mockJson = new MockJson();
        mockAddr = new MockAddr();
        vm.etch(WASMD_PRECOMPILE_ADDRESS, address(mockWasmd).code);
        vm.etch(JSON_PRECOMPILE_ADDRESS, address(mockJson).code);
        vm.etch(ADDR_PRECOMPILE_ADDRESS, address(mockAddr).code);
    }

    function testBalanceOf() public {
        vm.mockCall(
            WASMD_PRECOMPILE_ADDRESS,
            abi.encodeWithSignature("query(string,bytes)", MockCWContractAddress, bytes("{\"balance_of\":{\"owner\":\"sei19zhelek4q5lt4zam8mcarmgv92vzgqd3ux32jw\",\"token_id\":\"1\"}}")),
            abi.encode("{\"balance\":\"1\"}")
        );
        vm.mockCall(
            JSON_PRECOMPILE_ADDRESS,
            abi.encodeWithSignature("extractAsUint256(bytes,string)", bytes("{\"balance\":\"1\"}"), "balance"),
            abi.encode(1)
        );
        assertEq(pointer.balanceOf(MockCallerEVMAddr, 1), 1);
    }
    
    function testBalanceOfZeroAddress() public {
        vm.expectRevert(bytes("ERC1155: cannot query balance of zero address"));
        pointer.balanceOf(MockZeroAddress, 1);
    }

    function testBalanceOfBatch() public {
        vm.mockCall(
            WASMD_PRECOMPILE_ADDRESS,
            abi.encodeWithSignature("query(string,bytes)", MockCWContractAddress, bytes("{\"balance_of\":{\"owner\":\"sei19zhelek4q5lt4zam8mcarmgv92vzgqd3ux32jw\",\"token_id\":\"1\"}}")),
            abi.encode("{\"balance\":\"1\"}")
        );
        vm.mockCall(
            WASMD_PRECOMPILE_ADDRESS,
            abi.encodeWithSignature("query(string,bytes)", MockCWContractAddress, bytes("{\"balance_of\":{\"owner\":\"sei19zhelek4q5lt4zam8mcarmgv92vzgqd3ux32jw\",\"token_id\":\"2\"}}")),
            abi.encode("{\"balance\":\"2\"}")
        );
        vm.mockCall(
            WASMD_PRECOMPILE_ADDRESS,
            abi.encodeWithSignature("query(string,bytes)", MockCWContractAddress, bytes("{\"balance_of\":{\"owner\":\"sei19zhelek4q5lt4zam8mcarmgv92vzgqd3ux32jw\",\"token_id\":\"3\"}}")),
            abi.encode("{\"balance\":\"0\"}")
        );

        vm.mockCall(
            JSON_PRECOMPILE_ADDRESS,
            abi.encodeWithSignature("extractAsUint256(bytes,string)", bytes("{\"balance\":\"1\"}"), "balance"),
            abi.encode(1)
        );
        vm.mockCall(
            JSON_PRECOMPILE_ADDRESS,
            abi.encodeWithSignature("extractAsUint256(bytes,string)", bytes("{\"balance\":\"2\"}"), "balance"),
            abi.encode(2)
        );
        vm.mockCall(
            JSON_PRECOMPILE_ADDRESS,
            abi.encodeWithSignature("extractAsUint256(bytes,string)", bytes("{\"balance\":\"0\"}"), "balance"),
            abi.encode(0)
        );
        address[] memory owners = new address[](3);
        uint256[] memory ids = new uint256[](3);
        owners[0] = MockCallerEVMAddr;
        owners[1] = MockCallerEVMAddr;
        owners[2] = MockCallerEVMAddr;
        ids[0] = 1;
        ids[1] = 2;
        ids[2] = 3;
        uint256[] memory expectedResp = new uint256[](3);
        expectedResp[0] = 1;
        expectedResp[1] = 2;
        expectedResp[2] = 0;
        assertEq(pointer.balanceOfBatch(owners, ids), expectedResp);
    }

    function testBatchBalanceOfBadLength() public {
        uint256 idsLength = 1;
        uint256 valuesLength = 0;
        vm.expectRevert(
            abi.encodeWithSelector(
                IERC1155Errors.ERC1155InvalidArrayLength.selector,
                idsLength,
                valuesLength
            )
        );
        pointer.balanceOfBatch(new address[](valuesLength), new uint256[](idsLength));
    }

    function testUri() public {
        vm.mockCall(
            WASMD_PRECOMPILE_ADDRESS,
            abi.encodeWithSignature("query(string,bytes)", MockCWContractAddress, bytes("{\"token_info\":{\"token_id\":\"1\"}}")),
            abi.encode("{\"extension\": { \"animation_url\": null, \"attributes\": null, \"background_color\": null, \"description\": null, \"external_url\": null, \"image\": null, \"image_data\": null, \"name\": null, \"royalty_payment_address\": null, \"royalty_percentage\": null, \"youtube_url\": null }, \"token_uri\": \"test\" }")
        );
        
        vm.mockCall(
            JSON_PRECOMPILE_ADDRESS,
            abi.encodeWithSignature("extractAsBytes(bytes,string)", bytes("{\"extension\": { \"animation_url\": null, \"attributes\": null, \"background_color\": null, \"description\": null, \"external_url\": null, \"image\": null, \"image_data\": null, \"name\": null, \"royalty_payment_address\": null, \"royalty_percentage\": null, \"youtube_url\": null }, \"token_uri\": \"test\" }"), "token_uri"),
            abi.encode(bytes("test"))
        );
        assertEq(pointer.uri(1), "test");
    }

    function testIsApprovedForAll() public {
        vm.mockCall(
            WASMD_PRECOMPILE_ADDRESS,
            abi.encodeWithSignature("query(string,bytes)", MockCWContractAddress, bytes("{\"is_approved_for_all\":{\"owner\":\"sei19zhelek4q5lt4zam8mcarmgv92vzgqd3ux32jw\",\"operator\":\"sei1vldxw5dy5k68hqr4d744rpg9w8cqs54x4asdqe\"}}")),
            abi.encode("{\"approved\":true}")
        );
        vm.mockCall(
            JSON_PRECOMPILE_ADDRESS,
            abi.encodeWithSignature("extractAsUint256(bytes,string)", bytes("{\"approved\":true}"), "approved"),
            abi.encode(true)
        );
        assertEq(pointer.isApprovedForAll(MockCallerEVMAddr, MockOperatorEVMAddr), true);
    }
}
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IERC165 {
    function supportsInterface(bytes4 interfaceID) external view returns (bool);
}

interface IERC721 is IERC165 {
    function balanceOf(address owner) external view returns (uint balance);

    function ownerOf(uint tokenId) external view returns (address owner);

    function safeTransferFrom(address from, address to, uint tokenId) external;

    function safeTransferFrom(
        address from,
        address to,
        uint tokenId,
        bytes calldata data
    ) external;

    function transferFrom(address from, address to, uint tokenId) external;

    function approve(address to, uint tokenId) external;

    function getApproved(uint tokenId) external view returns (address operator);

    function setApprovalForAll(address operator, bool _approved) external;

    function isApprovedForAll(
        address owner,
        address operator
    ) external view returns (bool);
}

interface IERC721Enumerable {
    function totalSupply() external view returns (uint256);

    function tokenByIndex(uint256 _index) external view returns (uint256);

    function tokenOfOwnerByIndex(address _owner, uint256 _index) external view returns (uint256);
}

interface IERC721Receiver {
    function onERC721Received(
        address operator,
        address from,
        uint tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

contract ERC721 is IERC721 {
    event Transfer(address indexed from, address indexed to, uint indexed id);
    event Approval(address indexed owner, address indexed spender, uint indexed id);
    event ApprovalForAll(
        address indexed owner,
        address indexed operator,
        bool approved
    );

    // Mapping from token ID to owner address
    mapping(uint => address) internal _ownerOf;

    // Mapping from token ID to approved address
    mapping(uint => address) internal _approvals;

    // Mapping of owner addresses to an array of token ids they own
    mapping(address => []uint256) internal _ownerTokenIds;

    // Mapping of owner addresses to a mapping of token ids they own to their index
    mapping(address => mapping(uint256 => uint256)) internal _ownerTokenIdToIndex;

    // Keeps track of all token ids
    []uint256 internal _allTokenIds;

    // Mapping of token ids to their index
    mapping(uint256 => uint256) internal _allTokenIdsToIndex;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) public isApprovedForAll;

    function supportsInterface(bytes4 interfaceId) external pure returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC165).interfaceId;
    }

    function ownerOf(uint id) external view returns (address owner) {
        owner = _ownerOf[id];
        require(owner != address(0), "token doesn't exist");
    }

    function balanceOf(address owner) external view returns (uint) {
        require(owner != address(0), "owner = zero address");
        return _ownerTokenIds[owner].length;
    }

    function totalSupply() external view returns (uint256) {
        return _allTokenIds.length;
    }

    function setApprovalForAll(address operator, bool approved) external {
        isApprovedForAll[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function approve(address spender, uint id) external {
        address owner = _ownerOf[id];
        require(
            msg.sender == owner || isApprovedForAll[owner][msg.sender],
            "not authorized"
        );

        _approvals[id] = spender;

        emit Approval(owner, spender, id);
    }

    function getApproved(uint id) external view returns (address) {
        require(_ownerOf[id] != address(0), "token doesn't exist");
        return _approvals[id];
    }

    function _isApprovedOrOwner(
        address owner,
        address spender,
        uint id
    ) internal view returns (bool) {
        return (spender == owner ||
        isApprovedForAll[owner][spender] ||
            spender == _approvals[id]);
    }

    function transferFrom(address from, address to, uint id) public {
        require(from == _ownerOf[id], "from != owner");
        require(to != address(0), "transfer to zero address");

        require(_isApprovedOrOwner(from, msg.sender, id), "not authorized");

        _ownerOf[id] = to;

        delete _approvals[id];

        // add token to token ids owned by recipient
        _ownerTokenIdToIndex[to][id] = _ownerTokenIds[to].length;
        _ownerTokenIds[to].push(id);

        // remove token from token ids owned by sender
        _ownerTokenIds[from][_ownerTokenIdToIndex[from][id]] = _ownerTokenIds[from][_ownerTokenIdToIndex[from].length - 1];
        _ownerTokenIds[from].pop();
        delete _ownerTokenIdToIndex[from][id];

        emit Transfer(from, to, id);
    }

    function safeTransferFrom(address from, address to, uint id) external {
        require(
            to.code.length == 0 ||
            IERC721Receiver(to).onERC721Received(msg.sender, from, id, "") ==
            IERC721Receiver.onERC721Received.selector,
            "unsafe recipient"
        );
        transferFrom(from, to, id);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint id,
        bytes calldata data
    ) external {
        require(
            to.code.length == 0 ||
            IERC721Receiver(to).onERC721Received(msg.sender, from, id, data) ==
            IERC721Receiver.onERC721Received.selector,
            "unsafe recipient"
        );
        transferFrom(from, to, id);
    }

    function _mint(address to, uint id) internal {
        require(to != address(0), "mint to zero address");
        require(_ownerOf[id] == address(0), "already minted");

        _ownerOf[id] = to;

        _allTokenIdsToIndex[id] = _allTokenIds.length;
        _allTokenIds.push(id);
        _ownerTokenIdToIndex[to][id] = _ownerTokenIds[to].length;
        _ownerTokenIds[to].push(id);

        emit Transfer(address(0), to, id);
    }

    function _burn(uint id) internal {
        address owner = _ownerOf[id];
        require(owner != address(0), "not minted");

        delete _ownerOf[id];
        delete _approvals[id];

        allTokenIds[_allTokenIdsToIndex[id]] = allTokenIds[allTokenIds.length - 1];
        allTokenIds.pop();
        delete _allTokenIdsToIndex[id];

        _ownerTokenIds[to][_ownerTokenIdToIndex[to][id]] = _ownerTokenIds[to][_ownerTokenIdToIndex[to].length - 1];
        _ownerTokenIds[to].pop();
        delete _ownerTokenIdToIndex[to][id];

        emit Transfer(owner, address(0), id);
    }
}

contract MyNFT is ERC721 {

    // needed to concatenate the token ID to the URI
    function uintToString(uint _num) internal pure returns (string memory) {
        if (_num == 0) {
            return "0";
        }
        uint j = _num;
        uint len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint k = len;
        while (_num != 0) {
            k = k-1;
            uint8 temp = (48 + uint8(_num - _num / 10 * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _num /= 10;
        }
        return string(bstr);
    }

    function name() external pure returns (string memory _name) {
        return "MyNFT";
    }

    function symbol() external pure returns (string memory _symbol) {
        return "MYNFT";
    }

    function tokenURI(uint256 tokenId) external pure returns (string memory) {
        string memory numAsString = uintToString(tokenId);
        return string(abi.encodePacked("https://sei.io/token/", numAsString));
    }

    function mint(address to, uint id) external {
        _mint(to, id);
    }

    function burn(uint id) external {
        require(msg.sender == _ownerOf[id], "not owner");
        _burn(id);
    }

    function royaltyInfo(uint, uint256 salePrice) external pure returns (address receiver, uint256 royaltyAmount) {
        receiver = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;
        royaltyAmount = (salePrice * 500) / 10_000;
    }
}

contract MyNFTEnumerable is MyNFT {
    function tokenByIndex(uint256 index) external view returns (uint256) {
        require(index < _allTokenIds.length, "Index out of range");
        return _allTokenIds[index];
    }

    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256) {
        require(index < _ownerTokenIds[owner].length, "Index out of range");
        return _ownerTokenIds[owner][index];
    }

    function supportsInterface(bytes4 interfaceId) external pure override returns (bool) {
        return
            interfaceId == type(IERC721Enumerable).interfaceId ||
            super.supportsInterface(interfaceId);
    }
}

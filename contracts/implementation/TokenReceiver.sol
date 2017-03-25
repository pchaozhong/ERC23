pragma solidity ^0.4.8;

 /* ERC23 additions to ERC20 */

import "../interface/ERC23Receiver.sol";

contract TokenReceiver is ERC23Receiver {
  TokenSender tkn;

  struct TokenSender {
    address addr;
    address sender;
    address origin;
    uint256 value;
    bytes data;
    bytes4 sig;
  }

  function tokenFallback(address _sender, address _origin, uint _value, bytes _data) returns (bool ok) {
    if (!supportsToken(msg.sender)) return false;

    // Problem: This will do a sstore which is expensive gas wise. Find a way to keep it in memory.
    tkn = TokenSender(msg.sender, _sender, _origin, _value, _data, getSig(_data));
    __isTokenFallback = true;
    if (!address(this).delegatecall(_data)) return false;
    __isTokenFallback = false; // avoid doing an overwrite to .token, which would be more expensive

    return true;
  }

  function getSig(bytes _data) private returns (bytes4 sig) {
    uint l = _data.length < 4 ? _data.length : 4;
    for (uint i = 0; i < l; i++) {
      sig = bytes4(uint(sig) + uint(_data[i]) * (2 ** (8 * (l - 1 - i))));
    }
  }

  bool __isTokenFallback;

  modifier tokenPayable {
    if (!__isTokenFallback) throw;
    _;
  }

  function supportsToken(address token) returns (bool);
}

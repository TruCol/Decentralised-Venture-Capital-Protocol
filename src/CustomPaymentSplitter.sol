// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.23; // Specifies the Solidity compiler version.
import { console2 } from "forge-std/src/console2.sol";
import { ITier } from "../src/ITier.sol";
import { Tier } from "../src/Tier.sol";
import { TierInvestment } from "../src/TierInvestment.sol";
import { console } from "forge-std/src/console.sol";

/**
 * @title PaymentSplitter
 * @dev This contract can be used when payments need to be received by a group
 * of people and split proportionately to some number of dai they own.
 */
contract CustomPaymentSplitter {
  event PayeeAdded(address account, uint256 dai);
  event PaymentReleased(address to, uint256 amount);
  event SharesAdded(address to, uint256 amount);
  event PaymentReceived(address from, uint256 amount);

  uint256 private _totalDai;
  uint256 private _totalReleased;

  mapping(address => uint256) private _dai;
  mapping(address => uint256) private _released;
  address[] private _payees;
  uint256[] private _amountsOwed;
  address _owner;

  /**
   * @dev Constructor
   */
  constructor(address[] memory payees, uint256[] memory amountsOwed) payable {
    require(payees.length == amountsOwed.length);
    require(payees.length > 0);

    _amountsOwed = amountsOwed;
    _owner = msg.sender;
    for (uint256 i = 0; i < payees.length; i++) {
      _addPayee(payees[i], _amountsOwed[i]);
    }
  }

  /**
   * @dev payable fallback
   *    TODO: determine why this throws an error.
   */
  // function () external payable {
  // emit PaymentReceived(msg.sender, msg.value);
  // }
  // fallback() external payable {
  // emit PaymentReceived(msg.sender, msg.value);
  // }
  // This function can receive Ether from other accounts
  function deposit() public payable {
    // Event to log deposits
    emit PaymentReceived(msg.sender, msg.value);
  }

  /**
   * @return the total dai of the contract.
   */
  function totalDai() public view returns (uint256) {
    return _totalDai;
  }

  /**
   * @return the total amount already released.
   */
  function totalReleased() public view returns (uint256) {
    return _totalReleased;
  }

  /**
   * @return the dai of an account.
   */
  function getDai(address account) public view returns (uint256) {
    return _dai[account];
  }

  /**
   * @return the amount already released to an account.
   */
  function released(address account) public view returns (uint256) {
    return _released[account];
  }

  /**
   * @return the address of a payee.
   */
  function payee(uint256 index) public view returns (address) {
    return _payees[index];
  }

  /**
  Doubt: by not requiring msg.sender == account, one allows anyone to trigger
  the release of the investment funds. This can be inefficient for tax
  purposes.
   * @dev Release one of the payee's proportional payment.
   * @param account Whose payments will be released.
   */
  function release(address payable account) public {
    require(_dai[account] > 0, "The dai for account, was not larger than 0.");

    console2.log("_totalReleased=", _totalReleased);

    // Compute how much can be distributed.
    uint256 totalReceived = address(this).balance + (_totalReleased);
    console2.log("totalReceived=", totalReceived);

    // The amount the payee may receive is equal to the amount of outstanding
    // DAI, subtracted by the amount that has been released to that account.
    uint256 payment = _dai[account] - _released[account];

    require(payment > 0, "The amount to be paid was not larger than 0.");
    // Track the amount of DAI the payee has received through the release
    // process.
    _released[account] = _released[account] + (payment);

    // Track the total amount of DAI that has been released.
    _totalReleased = _totalReleased + (payment);

    // Perform the transfer. This is because when this function is triggered,
    // it computes how much that address is owed, and immediately pays it. If
    // this function is not called, one does not calculate how much an address
    // is owed.
    account.transfer(payment);
    emit PaymentReleased(account, payment);
  }

  /**
   * @dev Add a new payee to the contract.
   * @param account The address of the payee to add.
   * @param dai_ The number of dai owned by the payee.
   */
  function _addPayee(address account, uint256 dai_) private {
    // require(account != address(0));
    require(_dai[account] == 0);

    _payees.push(account);
    _dai[account] = dai_;
    _totalDai = _totalDai + dai_;
    emit PayeeAdded(account, dai_);
  }

  /**
   * Public counterpart of the _addPayee function, to add users that can withdraw
   *   funds after constructor initialisation.
   */
  function publicAddPayee(address account, uint256 dai_) public onlyOwner {
    require(account != address(0));
    require(dai_ > 0);
    require(_dai[account] == 0);

    _payees.push(account);
    _dai[account] = dai_;
    _totalDai = _totalDai + dai_;
    emit PayeeAdded(account, dai_);
  }

  /**
   * Public counterpart of the _addPayee function, to add users that can withdraw
   *   funds after constructor initialisation.
   */
  function publicAddSharesToPayee(address account, uint256 dai) public onlyOwner {
    require(dai > 0, "There was 0 dai incoming.");

    // TODO: assert account is in _dai array.
    console2.log("Adding %s dai to account:%s", dai, account);
    _dai[account] = _dai[account] + dai;
    _totalDai = _totalDai + dai;
    emit SharesAdded(account, dai);
  }

  function isPayee(address account) public view returns (bool) {
    for (uint256 i = 0; i < _payees.length; i++) {
      if (_payees[i] == account) {
        return true;
      }
    }
    return false;
  }

  /**
   * Used to ensure only the owner/creator of the constructor of this contract is
   *   able to call/use functions that use this function (modifier).
   */
  modifier onlyOwner() {
    require(msg.sender == _owner);
    _;
  }
}

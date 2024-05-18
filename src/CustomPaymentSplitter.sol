// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.25; // Specifies the Solidity compiler version.

interface ICustomPaymentSplitter {
  function deposit() external payable;

  function release() external;

  function publicAddPayee(address account, uint256 dai_) external;

  function publicAddSharesToPayee(address account, uint256 dai) external;

  function released(address account) external view returns (uint256 amountReleased);

  function isPayee(address account) external view returns (bool accountIsPayee);
}

/**
 * @title PaymentSplitter
 * @dev This contract can be used when payments need to be received by a group
 * of people and split proportionately to some number of dai they own.
 */
contract CustomPaymentSplitter is ICustomPaymentSplitter {
  uint256 private _totalDai;
  uint256 private _totalReleased;

  // Not yet supported by Prettier
  // mapping(address  _somePayee => uint256  _someDaiOwed) private _dai;
  // mapping(address  _payedEntity => uint256  _amount_payed) private _released;
  // solhint-disable-next-line named-parameters-mapping
  mapping(address => uint256) private _dai;
  // solhint-disable-next-line named-parameters-mapping
  mapping(address => uint256) private _released;

  address[] private _payees;
  uint256[] private _amountsOwed;
  address private immutable _OWNER;

  event PayeeAdded(address indexed account, uint256 indexed dai);
  event PaymentReleased(address indexed to, uint256 indexed amount);
  event SharesAdded(address indexed to, uint256 indexed amount);
  event PaymentReceived(address indexed from, uint256 indexed amount);

  /**
   * Used to ensure only the owner/creator of the constructor of this contract is
   *   able to call/use functions that use this function (modifier).
   */
  modifier onlyOwner() {
    require(msg.sender == _OWNER, "CustomPaymentSplitter: The sender of this message is not the owner.");
    _;
  }

  /**
  @notice This constructor initializes the `CustomPaymentSplitter` contract.

  @dev This constructor performs the following actions:

  1. Validates that the provided lists of payees and corresponding amounts owed have
  the same length. It ensures at least one payee is specified. That implicitly
  veries that at least one amountsOwed element is given.

  2. Sets the contract owner to the message sender (`msg.sender`). This contract
  is designed to be initialised by the DecentralisedInvestmentManager contract.

  3. Stores the provided `amountsOwed` array in the internal `_amountsOwed`
  variable.

  4. Iterates through the `payees` and `amountsOwed` arrays, calling the
  `_addPayee` internal function for each element to register payees and their
  initial shares.

  **Important Notes:**

  * The `CustomPaymentSplitter` contract is designed for splitting payments among
  multiple payees based on predefined shares. It is a modificiation of the
  PaymentSplitter contract by OpenZeppelin.

  @param payees A list of wallet addresses representing the people that can
  receive money.
  @param amountsOwed A list of WEI amounts representing the initial shares
  allocated to each payee.
  */
  // solhint-disable-next-line comprehensive-interface
  constructor(address[] memory payees, uint256[] memory amountsOwed) public payable {
    require(payees.length == amountsOwed.length, "The nr of payees is not equal to the nr of amounts owed.");
    require(payees.length > 0, "There are not more than 0 payees.");

    _OWNER = msg.sender;
    _amountsOwed = amountsOwed;

    uint256 nrOfPayees = payees.length;
    uint256 totalDaiCounter = _totalDai; // Prevent updating state var in loop.
    for (uint256 i = 0; i < nrOfPayees; ++i) {
      _addPayee(payees[i], _amountsOwed[i]);
      totalDaiCounter += _amountsOwed[i];
    }
    _totalDai += totalDaiCounter;
  }

  /**
  @notice This function allows a payee to claim their outstanding wei balance.

  @dev This function is designed to be called by payees to withdraw their share of
  collected DAI. It performs the following actions:

  1. Validates that the payee's outstanding wei balance (the difference between
  their total nr of "shares" and any previous releases) is greater than zero.

  2. Calculates the amount to be paid to the payee by subtracting any previously
  released wei from their initial share.

  3. Verifies that the calculated payment amount is greater than zero.

  4. Updates the internal accounting for the payee's released wei and the total
  contract-wide released wei.

  5. Transfers the calculated payment amount of wei to the payee's address using
  a secure `transfer` approach.

  6. Emits a `PaymentReleased` event to log the payment details.

  **Important Notes:**
  * Payees are responsible for calling this function to claim their outstanding
  balances.

  */
  function release() public override {
    address payable account = payable(msg.sender);
    require(_dai[account] > 0, "The dai for account, was not larger than 0.");

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
    emit PaymentReleased(account, payment);
    account.transfer(payment);
  }

  /**
   * Public counterpart of the _addPayee function, to add users that can withdraw
   *   funds after constructor initialisation.
   */
  function publicAddPayee(address account, uint256 dai_) public override onlyOwner {
    require(account != address(this), "This account is equal to the address of this account.");
    require(dai_ > 0, "The number of incoming dai is not larger than 0.");
    require(_dai[account] == 0, "This account already has some currency.");

    _payees.push(account);
    _dai[account] = dai_;
    _totalDai = _totalDai + dai_;
    emit PayeeAdded(account, dai_);
  }

  /**
  @notice This function allows the contract owner to add additional "shares" to an existing payee.

  @dev This function increases the "share" allocation of a registered payee. It performs
  the following actions:

  1. Validates that the additional share amount (in WEI) is greater than zero.

  2. Verifies that the payee address already exists in the `_dai` mapping (implicit
  through requirement check).

  3. Updates the payee's share balance in the `_dai` mapping by adding the provided
  `dai` amount.

  4. Updates the contract-wide total DAI amount by adding the provided `dai` amount.

  5. Emits a `SharesAdded` event to log the details of the share increase.

  **Important Notes:**

  * This function can only be called by the contract owner _dim. It cannot be
  called by the projectLead.
  * The payee must already be registered with the contract to receive additional
  shares.

  @param account The address of the payee to receive additional shares.
  @param dai The amount of additional DAI shares to be allocated (in WEI).

  */
  function publicAddSharesToPayee(address account, uint256 dai) public override onlyOwner {
    require(dai > 0, "There were 0 dai shares incoming.");

    // One can not assert the account is already in _dai, because inherently in
    // Solidity, a mapping contains all possible options already. So it will
    // always return true. Furthermore, all values are initialised at 0 for
    // this mapping, which also is a valid value for an account that is
    // already in there.
    _dai[account] = _dai[account] + dai;
    _totalDai = _totalDai + dai;
    emit SharesAdded(account, dai);
  }

  /**
  @notice This function is used to deposit funds into the `CustomPaymentSplitter`
  contract.

  @dev This function allows anyone to deposit funds into the contract. It primarily
  serves as a way to collect investment funds or other revenue streams. The function
  logs the deposit details by emitting a `PaymentReceived` event.

  **Important Notes:**

  * There is no restriction on who can call this function.
  * TODO: Consider implementing access control mechanisms if only specific addresses
  should be allowed to deposit funds. This may be important because some
  business logic/balance checks may malfunction if unintentional funds come in.

  */
  function deposit() public payable override {
    // Event to log deposits
    emit PaymentReceived(msg.sender, msg.value);
  }

  /**
  @notice This function retrieves the total amount of wei that has already been released to a specific payee.

  @dev This function is a view function, meaning it doesn't modify the contract's state. It returns the accumulated
  amount of wei that has been released to the provided payee address.

  @param account The address of the payee for whom to retrieve the released DAI amount.

  @return amountReleased The total amount of DAI (in WEI) released to the payee.
  */
  function released(address account) public view override returns (uint256 amountReleased) {
    amountReleased = _released[account];
    return amountReleased;
  }

  /**
  @notice This function verifies if a specified address is registered as a payee in the contract.

  @dev This function is a view function and does not modify the contract's state. It iterates through the
  internal `_payees` array to check if the provided `account` address exists within the list of registered payees.

  @param account The address to be checked against the registered payees.

  @return accountIsPayee True if the address is a registered payee, False otherwise.
  */
  function isPayee(address account) public view override returns (bool accountIsPayee) {
    uint256 nrOfPayees = _payees.length;
    accountIsPayee = false;
    for (uint256 i = 0; i < nrOfPayees; ++i) {
      if (_payees[i] == account) {
        accountIsPayee = true;
        return accountIsPayee;
      }
    }
    return accountIsPayee;
  }

  /**
  @notice This private function adds a new payee to the contract.

  @dev This function is private and can only be called by other functions within the contract. It performs the
  following actions:

  1. Validates that the payee address is not already registered (by checking if the corresponding `wei` share balance
  is zero).

  2. Adds the payee's address to the internal `_payees` array.

  3. Sets the payee's initial share balance in the `_dai` mapping.

  4. Updates the contract-wide total DAI amount to reflect the addition of the new payee's share.

  5. Emits a `PayeeAdded` event to log the details of the new payee.

  @param account The address of the payee to be added.
  @param dai_ The amount of wei allocated as the payee's initial share.

  */
  function _addPayee(address account, uint256 dai_) private {
    require(_dai[account] == 0, "This account already is owed some currency.");

    _payees.push(account);
    _dai[account] = dai_;
    emit PayeeAdded(account, dai_);
  }
}

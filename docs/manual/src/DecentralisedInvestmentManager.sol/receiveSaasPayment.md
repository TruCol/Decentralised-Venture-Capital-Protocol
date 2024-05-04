# receiveSaasPayment

This function is used by users of the SAAS to perform payments to keep using
the service. The function receives the payment and distributes it to the
investors and project lead.

## Possible abuse

- people could abuse this function to get a proof-of-payment without having
  performed a (complete) payment.
- people could get someone else's proof of payment.
- people could complete a payment for someone else, leading to unexpected consequences.
- A payment may be too low, or to high, which may result in unexpected consequences.
- An investor may pay itself through this mechanism.
- A payment may freeze the contract.
- Someone may abuse this method to trigger an undesired payment somewhere else.
- Someone may abuse this method to create/store invalid/incorrect/undesirable
  data within the contract.
- Someone may be able to retrieve money from the contract using this payment.

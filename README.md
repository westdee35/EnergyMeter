# Energy Meter Smart Contract

A decentralized pay-as-you-go energy meter system implemented as a Clarity smart contract on the Stacks blockchain.

## Overview

This smart contract enables a decentralized energy metering system where users can:
- Create prepaid energy meters
- Top up their meter balance
- Monitor their consumption
- Cancel service and receive refunds

Providers can:
- Record energy consumption
- Automatically receive payments based on usage

## Features

- **Prepaid System**: Users prepay in STX tokens
- **Automatic Payments**: Providers receive payments automatically based on consumption
- **Secure**: Built-in safety checks and access controls
- **Transparent**: All transactions are recorded on the blockchain
- **Refundable**: Users can cancel service and receive remaining balance

## Contract Functions

### Public Functions

```clarity
(define-public (create-meter (provider principal) (rate uint) (prepay uint)))
(define-public (record-consumption (id uint) (units uint)))
(define-public (top-up (id uint) (amount uint)))
(define-public (cancel (id uint)))
```

### Read-Only Functions

```clarity
(define-read-only (get-meter (id uint)))
```

## Error Codes

| Code | Description |
|------|-------------|
| u100 | Meter does not exist |
| u101 | Not authorized (user) |
| u102 | Not authorized (provider) |
| u103 | Meter not active |
| u104 | Insufficient funds |
| u200 | Invalid parameters |
| u201 | Transfer failed |

## Usage

### Creating a Meter
```clarity
;; As a user
(contract-call? .energy-meter create-meter 
    'SP2JXKMSH007NPYAQHKJPQMAQYAD90NQGTVJVQ02B  ;; provider
    u100                                          ;; rate per unit
    u1000)                                        ;; initial prepayment
```

### Recording Consumption
```clarity
;; As a provider
(contract-call? .energy-meter record-consumption 
    u1      ;; meter ID
    u5)     ;; units consumed
```

## Development

### Prerequisites
- [Clarinet](https://github.com/hirosystems/clarinet)
- [Stacks CLI](https://docs.stacks.co/cli/get-started)

### Testing
```bash
clarinet test
```

### Deployment
```bash
clarinet deploy
```

## Security Considerations

- All functions include proper access controls
- Token transfers use safe patterns
- Balance checks before transfers
- Protection against reentrancy


## Contributing

Pull requests are welcome. For major changes, please open an issue first to discuss what you would like to change.

## Acknowledgments

- Stacks Foundation
- Clarity Language Documentation
- Energy Meter Standards

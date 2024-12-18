# BidWise - Decentralized Auction Platform

BidWise is a decentralized auction platform built on the Stacks blockchain that enables users to create and participate in auctions for both NFTs and fungible tokens. The platform supports time-limited bids, reserve prices, and automatic auction closure mechanisms.

## Features

### Core Functionality
- Create auctions for NFTs and fungible tokens
- Time-limited bidding with automatic closure
- Reserve price support
- Secure bid placement and tracking
- Automatic refund mechanism for losing bids
- Support for both NFTs and STX/fungible tokens

### Smart Contract Security
- Input validation for all critical parameters
- Proper error handling and status tracking
- Automated auction state management
- Protection against common auction vulnerabilities
- Secure refund mechanism for unsuccessful bids

## Technical Specifications

### Auction Parameters
- `token-id`: Unique identifier for the token being auctioned (1 to 1,000,000)
- `start-block`: Block height when the auction begins
- `end-block`: Block height when the auction ends
- `reserve-price`: Minimum acceptable bid (must be ≥ 1)
- `is-nft`: Boolean flag indicating if the auctioned item is an NFT

### Error Codes
```clarity
ERR-NOT-AUTHORIZED (u100): Unauthorized access or invalid timing
ERR-AUCTION-ENDED (u101): Auction has already ended
ERR-AUCTION-NOT-ENDED (u102): Auction hasn't ended yet
ERR-BID-TOO-LOW (u103): Bid amount is too low
ERR-ALREADY-CLAIMED (u104): Auction rewards already claimed
ERR-RESERVE-NOT-MET (u105): Reserve price not met
ERR-NO-BID-TO-REFUND (u106): No bid found for refund
ERR-ALREADY-REFUNDED (u107): Bid already refunded
ERR-AUCTION-ACTIVE (u108): Auction still active
ERR-TRANSFER-FAILED (u109): Asset transfer failed
ERR-INVALID-AUCTION (u110): Invalid auction data
ERR-INVALID-TOKEN (u111): Invalid token ID
ERR-INVALID-RESERVE (u112): Invalid reserve price
```

## Smart Contract API

### Read-Only Functions

#### `get-auction`
Retrieves auction details by ID.
```clarity
(get-auction (auction-id uint)) => (optional {auction-data})
```

#### `get-bid`
Retrieves bid details for a specific auction and bidder.
```clarity
(get-bid (auction-id uint) (bidder principal)) => (optional {bid-data})
```

#### `is-auction-ended`
Checks if an auction has ended.
```clarity
(is-auction-ended (auction-id uint)) => bool
```

### Public Functions

#### `create-auction`
Creates a new auction.
```clarity
(create-auction 
    (token-id uint)
    (start-block uint)
    (end-block uint)
    (reserve-price uint)
    (is-nft bool)
) => (response uint uint)
```

#### `place-bid`
Places a bid on an active auction.
```clarity
(place-bid 
    (auction-id uint)
    (bid-amount uint)
) => (response bool uint)
```

#### `end-auction`
Ends an auction and transfers assets.
```clarity
(end-auction 
    (auction-id uint)
) => (response bool uint)
```

#### `claim-refund`
Claims refund for losing bids.
```clarity
(claim-refund 
    (auction-id uint)
) => (response bool uint)
```

## Usage Examples

### Creating an Auction
```clarity
(contract-call? .bidwise create-auction u1 u100 u1000 u1000000 true)
```

### Placing a Bid
```clarity
(contract-call? .bidwise place-bid u1 u2000000)
```

### Ending an Auction
```clarity
(contract-call? .bidwise end-auction u1)
```

### Claiming a Refund
```clarity
(contract-call? .bidwise claim-refund u1)
```

## Installation

1. Clone the repository:
```bash
git clone https://github.com/yourusername/bidwise.git
```

2. Install dependencies:
```bash
npm install
```

3. Run tests:
```bash
clarinet test
```

## Development

### Prerequisites
- Clarinet
- Node.js
- NPM or Yarn

### Testing
Run the test suite:
```bash
clarinet test
```

### Deployment
Deploy to testnet:
```bash
clarinet deploy --testnet
```

## Security Considerations

1. **Input Validation**
   - All input parameters are validated
   - Token IDs must be within valid range
   - Reserve prices must meet minimum requirements

2. **Timing Controls**
   - Block height-based timing
   - Automatic auction closure
   - Protection against premature endings

3. **Access Controls**
   - Seller-only auction management
   - Winner-only asset claims
   - Proper authorization checks

4. **Asset Safety**
   - Secure asset transfers
   - Automated refund mechanism
   - Protection against double-claims

## Contributing

1. Fork the repository
2. Create your feature branch
3. Commit your changes
4. Push to the branch
5. Create a new Pull Request

## Acknowledgments

- Stacks Blockchain team
- Clarity language documentation
- Community contributors

## Contact

For questions and support, please open an issue in the GitHub repository .
;; BidWise - Decentralized Auction Platform
;; Error Codes
(define-constant ERR-NOT-AUTHORIZED (err u100))
(define-constant ERR-AUCTION-ENDED (err u101))
(define-constant ERR-AUCTION-NOT-ENDED (err u102))
(define-constant ERR-BID-TOO-LOW (err u103))
(define-constant ERR-ALREADY-CLAIMED (err u104))
(define-constant ERR-RESERVE-NOT-MET (err u105))

;; Data Maps
(define-map auctions
    { auction-id: uint }
    {
        seller: principal,
        token-id: uint,
        start-block: uint,
        end-block: uint,
        reserve-price: uint,
        highest-bid: uint,
        highest-bidder: (optional principal),
        is-nft: bool,
        claimed: bool
    }
)

(define-map bids
    { auction-id: uint, bidder: principal }
    { bid-amount: uint }
)

;; Storage
(define-data-var last-auction-id uint u0)

;; Read-Only Functions
(define-read-only (get-auction (auction-id uint))
    (map-get? auctions { auction-id: auction-id })
)

(define-read-only (get-bid (auction-id uint) (bidder principal))
    (map-get? bids { auction-id: auction-id, bidder: bidder })
)

(define-read-only (is-auction-ended (auction-id uint))
    (let (
        (auction (unwrap! (get-auction auction-id) false))
        (current-block block-height)
    )
        (>= current-block (get end-block auction))
    )
)

;; Public Functions
(define-public (create-auction (token-id uint) (start-block uint) (end-block uint) (reserve-price uint) (is-nft bool))
    (let (
        (auction-id (+ (var-get last-auction-id) u1))
    )
        (asserts! (> end-block start-block) ERR-NOT-AUTHORIZED)
        (asserts! (>= start-block block-height) ERR-NOT-AUTHORIZED)
        
        (map-set auctions
            { auction-id: auction-id }
            {
                seller: tx-sender,
                token-id: token-id,
                start-block: start-block,
                end-block: end-block,
                reserve-price: reserve-price,
                highest-bid: u0,
                highest-bidder: none,
                is-nft: is-nft,
                claimed: false
            }
        )
        
        (var-set last-auction-id auction-id)
        (ok auction-id)
    )
)

(define-public (place-bid (auction-id uint) (bid-amount uint))
    (let (
        (auction (unwrap! (get-auction auction-id) ERR-NOT-AUTHORIZED))
        (current-block block-height)
        (current-highest-bid (get highest-bid auction))
    )
        ;; Check if auction is active
        (asserts! (>= current-block (get start-block auction)) ERR-NOT-AUTHORIZED)
        (asserts! (< current-block (get end-block auction)) ERR-AUCTION-ENDED)
        
        ;; Check if bid is high enough
        (asserts! (> bid-amount current-highest-bid) ERR-BID-TOO-LOW)
        
        ;; Update auction with new highest bid
        (map-set auctions
            { auction-id: auction-id }
            (merge auction {
                highest-bid: bid-amount,
                highest-bidder: (some tx-sender)
            })
        )
        
        ;; Record bid
        (map-set bids
            { auction-id: auction-id, bidder: tx-sender }
            { bid-amount: bid-amount }
        )
        
        (ok true)
    )
)

(define-public (end-auction (auction-id uint))
    (let (
        (auction (unwrap! (get-auction auction-id) ERR-NOT-AUTHORIZED))
    )
        ;; Check if auction can be ended
        (asserts! (is-auction-ended auction-id) ERR-AUCTION-NOT-ENDED)
        (asserts! (not (get claimed auction)) ERR-ALREADY-CLAIMED)
        
        ;; Check if reserve price was met
        (asserts! (>= (get highest-bid auction) (get reserve-price auction)) ERR-RESERVE-NOT-MET)
        
        ;; Mark auction as claimed
        (map-set auctions
            { auction-id: auction-id }
            (merge auction { claimed: true })
        )
        
        ;; Transfer asset and payment
        ;; Note: Actual token transfer implementation would go here
        ;; This would vary based on whether it's an NFT or fungible token
        
        (ok true)
    )
)

;; Helper Functions
(define-private (transfer-asset (auction-id uint))
    ;; Implementation for asset transfer
    ;; This would handle both NFT and fungible token transfers
    (ok true)
)

;; Error Handling Utilities
(define-private (validate-auction (auction-id uint))
    (is-some (get-auction auction-id))
)
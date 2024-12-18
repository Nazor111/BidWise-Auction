;; BidWise - Decentralized Auction Platform
;; Error Codes
(define-constant ERR-NOT-AUTHORIZED (err u100))
(define-constant ERR-AUCTION-ENDED (err u101))
(define-constant ERR-AUCTION-NOT-ENDED (err u102))
(define-constant ERR-BID-TOO-LOW (err u103))
(define-constant ERR-ALREADY-CLAIMED (err u104))
(define-constant ERR-RESERVE-NOT-MET (err u105))
(define-constant ERR-NO-BID-TO-REFUND (err u106))
(define-constant ERR-ALREADY-REFUNDED (err u107))
(define-constant ERR-AUCTION-ACTIVE (err u108))
(define-constant ERR-TRANSFER-FAILED (err u109))
(define-constant ERR-INVALID-AUCTION (err u110))

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
        claimed: bool,
        auto-closed: bool
    }
)

(define-map bids
    { auction-id: uint, bidder: principal }
    { 
        bid-amount: uint,
        refunded: bool
    }
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
                claimed: false,
                auto-closed: false
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
        ;; Check if auction needs auto-closure
        (try! (check-and-auto-close auction-id))
        
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
        
        ;; Record bid with refund status
        (map-set bids
            { auction-id: auction-id, bidder: tx-sender }
            { 
                bid-amount: bid-amount,
                refunded: false
            }
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
        (asserts! (not (get auto-closed auction)) ERR-ALREADY-CLAIMED)
        
        ;; Check if reserve price was met
        (asserts! (>= (get highest-bid auction) (get reserve-price auction)) ERR-RESERVE-NOT-MET)
        
        ;; Mark auction as claimed
        (map-set auctions
            { auction-id: auction-id }
            (merge auction { 
                claimed: true,
                auto-closed: true
            })
        )
        
        ;; Transfer asset and payment
        (match (transfer-asset auction-id)
            success (ok true)
            error (err error)
        )
    )
)

(define-public (claim-refund (auction-id uint))
    (let (
        (auction (unwrap! (get-auction auction-id) ERR-NOT-AUTHORIZED))
        (bid (unwrap! (get-bid auction-id tx-sender) ERR-NO-BID-TO-REFUND))
    )
        ;; Verify auction is ended or auto-closed
        (asserts! (or (is-auction-ended auction-id) (get auto-closed auction)) ERR-AUCTION-ACTIVE)
        
        ;; Check if bid was not already refunded
        (asserts! (not (get refunded bid)) ERR-ALREADY-REFUNDED)
        
        ;; Check if bidder is not the winner
        (asserts! (not (is-eq (some tx-sender) (get highest-bidder auction))) ERR-NOT-AUTHORIZED)
        
        ;; Mark bid as refunded
        (map-set bids
            { auction-id: auction-id, bidder: tx-sender }
            (merge bid { refunded: true })
        )
        
        ;; Process refund
        (match (process-refund tx-sender (get bid-amount bid))
            success (ok true)
            error (err error)
        )
    )
)

;; Private Functions
(define-private (check-and-auto-close (auction-id uint))
    (let (
        (auction (unwrap! (get-auction auction-id) ERR-NOT-AUTHORIZED))
    )
        (if (and 
            (is-auction-ended auction-id)
            (not (get auto-closed auction))
            )
            (begin
                (map-set auctions
                    { auction-id: auction-id }
                    (merge auction { auto-closed: true })
                )
                (ok true)
            )
            (ok true)
        )
    )
)

(define-private (transfer-asset (auction-id uint))
    (let (
        (auction (unwrap! (get-auction auction-id) ERR-INVALID-AUCTION))
        (winner (unwrap! (get highest-bidder auction) ERR-INVALID-AUCTION))
    )
        (ok u1) ;; Placeholder for actual token transfer implementation
    )
)

(define-private (process-refund (bidder principal) (amount uint))
    (if (> amount u0)
        (ok u1) ;; Placeholder for actual refund implementation
        ERR-TRANSFER-FAILED
    )
)

;; Error Handling Utilities
(define-private (validate-auction (auction-id uint))
    (is-some (get-auction auction-id))
)
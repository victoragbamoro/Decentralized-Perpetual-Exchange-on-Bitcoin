;; Constants
(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_NOT_AUTHORIZED (err u100))
(define-constant ERR_INVALID_PARAMETER (err u101))
(define-constant ERR_INSUFFICIENT_MARGIN (err u102))
(define-constant ERR_INVALID_PRICE (err u103))
(define-constant ERR_POSITION_NOT_FOUND (err u104))
(define-constant ERR_ORACLE_NOT_FOUND (err u105))
(define-constant ERR_UNAVAILABLE_LIQUIDITY (err u106))
(define-constant ERR_MAX_LEVERAGE_EXCEEDED (err u107))
(define-constant ERR_MIN_COLLATERAL_NOT_MET (err u108))
(define-constant ERR_ORDER_NOT_FOUND (err u109))
(define-constant ERR_POSITION_UNDER_LIQUIDATION (err u110))
(define-constant ERR_MARKET_PAUSED (err u111))
(define-constant ERR_INVALID_ORACLE_DATA (err u112))
(define-constant ERR_PRICE_IMPACT_TOO_HIGH (err u113))
(define-constant ERR_FUNDING_UPDATE_TOO_SOON (err u114))
(define-constant ERR_TRADE_SIZE_TOO_SMALL (err u115))
(define-constant ERR_TRADE_SIZE_TOO_LARGE (err u116))
(define-constant ERR_WRONG_COUNTERPARTY (err u117))
(define-constant ERR_DUPLICATE_ORDER_ID (err u118))

;; Position side types
(define-constant SIDE_LONG u1)
(define-constant SIDE_SHORT u2)

;; Order types
(define-constant ORDER_MARKET u1)
(define-constant ORDER_LIMIT u2)
(define-constant ORDER_STOP u3)
(define-constant ORDER_STOP_LIMIT u4)

;; Precision constants - use fixed point math with 8 decimal places
(define-constant PRECISION u100000000) ;; 10^8 for 8 decimal places of precision

;; Market configuration
(define-map markets
  { market-id: uint }
  {
    asset-pair: (string-ascii 10), ;; e.g., "BTC-USD"
    oracle-id: (buff 32),
    mark-price: uint,
    index-price: uint,
    funding-rate: int, ;; Can be positive or negative
    last-funding-timestamp: uint,
    open-interest-long: uint,
    open-interest-short: uint,
    max-leverage: uint,
    liquidity-pool-balance: uint,
    is-active: bool,
    max-price-deviation: uint, ;; Maximum allowed deviation between mark and index price
    max-open-interest: uint    ;; Maximum open interest per side
  }
)

;; User positions
(define-map positions
  { market-id: uint, trader: principal }
  {
    size: int,              ;; Position size (positive for long, negative for short)
    collateral: uint,       ;; Collateral amount in STX
    entry-price: uint,      ;; Average entry price
    last-cumulative-funding: int, ;; Last funding snapshot
    liquidation-price: uint, ;; Price at which position gets liquidated
    last-updated-block: uint, ;; Last block when position was updated
    realized-pnl: int,      ;; Realized profit and loss
    leverage: uint,         ;; Current leverage used
    margin-ratio: uint      ;; Current margin ratio
  }
)

;; Order book
(define-map orders
  { order-id: (buff 32) }
  {
    market-id: uint,
    trader: principal,
    side: uint,             ;; SIDE_LONG or SIDE_SHORT
    size: uint,             ;; Order size
    price: uint,            ;; Limit price, or trigger price for stop orders
    limit-price: (optional uint), ;; For stop-limit orders
    collateral: uint,       ;; Amount of collateral to use
    leverage: uint,         ;; Requested leverage
    order-type: uint,       ;; ORDER_MARKET, ORDER_LIMIT, etc.
    created-at: uint,       ;; Block height when order was created
    status: uint,           ;; 0: open, 1: filled, 2: cancelled, 3: expired
    filled-size: uint,      ;; Amount filled so far
    average-fill-price: uint ;; Average fill price
  }
)

;; Oracle price feeds
(define-map oracle-price-feeds
  { oracle-id: (buff 32) }
  {
    price: uint,
    timestamp: uint,
    source: (string-ascii 32),
    heartbeat: uint, ;; Maximum time between updates before price is considered stale
    providers: (list 10 principal) ;; List of authorized price providers
  }
)

;; User account information
(define-map user-accounts
  { user: principal }
  {
    total-collateral: uint,
    unrealized-pnl: int,
    realized-pnl: int,
    margin-ratio: uint,
    total-fees-paid: uint,
    total-funding-paid: int
  }
)

;; Trading volume tracking
(define-map trading-volumes
  { market-id: uint, trader: principal, period: uint } ;; period: 0 = daily, 1 = weekly, 2 = monthly
  {
    volume: uint,
    timestamp: uint
  }
)

;; Funding rate history
(define-map funding-history
  { market-id: uint, timestamp: uint }
  {
    funding-rate: int,
    premium-index: int
  }
)

;; Event counters for pagination
(define-data-var trade-counter uint u0)
(define-data-var liquidation-counter uint u0)
(define-data-var funding-counter uint u0)

;; Add or update an oracle price feed
(define-public (set-oracle-price-feed
                (oracle-id (buff 32))
                (source (string-ascii 32))
                (heartbeat uint)
                (providers (list 10 principal)))
  (begin
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_NOT_AUTHORIZED)
    
    (map-set oracle-price-feeds
      { oracle-id: oracle-id }
      {
        price: u0,
        timestamp: u0,
        source: source,
        heartbeat: heartbeat,
        providers: providers
      }
    )
    (ok true)
  )
)

;; Read-only function to get current price from oracle
(define-read-only (get-oracle-price (oracle-id (buff 32)))
  (let (
    (oracle-data (unwrap! (map-get? oracle-price-feeds { oracle-id: oracle-id }) ERR_ORACLE_NOT_FOUND))
    (current-time stacks-block-height)
  )
    ;; Check if price is stale
    (asserts! (<= (- current-time (get timestamp oracle-data)) (get heartbeat oracle-data)) ERR_INVALID_ORACLE_DATA)
    (ok (get price oracle-data))
  )
)


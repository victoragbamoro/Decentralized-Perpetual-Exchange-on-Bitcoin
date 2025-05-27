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

;; Update markets that use a specific oracle
(define-private (update-markets-with-oracle (oracle-id (buff 32)) (price uint))
  (begin
    ;; This would iterate through markets in a real implementation
    ;; For Clarity, we would need a different approach like indexing or event tracking
    ;; Simplified implementation for demonstration
    (ok true)
  )
)

;; Get cumulative funding for a market since inception
(define-read-only (get-cumulative-funding (market-id uint))
  ;; In production, this would calculate based on funding rate history
  ;; Simplified version for demonstration
  (let (
    (market (unwrap! (map-get? markets { market-id: market-id }) (to-int u0)))
    (current-funding-rate (get funding-rate market))
  )
    current-funding-rate ;; Simplified - should accumulate historical rates
  )
)

;; Create a new position
(define-private (create-new-position
                (market-id uint)
                (trader principal)
                (size int)
                (collateral uint)
                (entry-price uint)
                (liquidation-price uint)
                (leverage uint)
                (margin-ratio uint))
  (begin
    (map-set positions
      { market-id: market-id, trader: trader }
      {
        size: size,
        collateral: collateral,
        entry-price: entry-price,
        last-cumulative-funding: (get-cumulative-funding market-id),
        liquidation-price: liquidation-price,
        last-updated-block: stacks-block-height,
        realized-pnl: 0,
        leverage: leverage,
        margin-ratio: margin-ratio
      }
    )
    (ok true)
  )
)

;; Additional constants for new features
(define-constant ERR_REWARD_POOL_EMPTY (err u119))
(define-constant ERR_INSURANCE_FUND_INSUFFICIENT (err u120))
(define-constant ERR_REFERRAL_NOT_FOUND (err u121))
(define-constant ERR_VAULT_NOT_FOUND (err u122))
(define-constant ERR_STRATEGY_NOT_APPROVED (err u123))
(define-constant ERR_GOVERNANCE_PROPOSAL_NOT_FOUND (err u124))
(define-constant ERR_STAKING_PERIOD_NOT_EXPIRED (err u125))
(define-constant ERR_CROSS_MARGIN_INSUFFICIENT (err u126))

;; Staking reward tiers
(define-constant TIER_BRONZE u1)
(define-constant TIER_SILVER u2)
(define-constant TIER_GOLD u3)
(define-constant TIER_PLATINUM u4)

;; Governance proposal types
(define-constant PROPOSAL_PARAMETER_CHANGE u1)
(define-constant PROPOSAL_MARKET_ADDITION u2)
(define-constant PROPOSAL_FEE_STRUCTURE u3)
(define-constant PROPOSAL_EMERGENCY_PAUSE u4)

;; LIQUIDITY MINING & REWARDS SYSTEM
(define-map liquidity-providers
  { provider: principal, market-id: uint }
  {
    staked-amount: uint,
    reward-debt: uint,
    accumulated-rewards: uint,
    staking-timestamp: uint,
    lock-period: uint,
    tier: uint
  }
)

(define-map reward-pools
  { market-id: uint }
  {
    total-staked: uint,
    reward-per-block: uint,
    accumulated-reward-per-share: uint,
    last-reward-block: uint,
    total-rewards-distributed: uint
  }
)

;; INSURANCE FUND SYSTEM
(define-map insurance-fund
  { market-id: uint }
  {
    balance: uint,
    contribution-rate: uint, ;; Percentage of trading fees that go to insurance
    deficit-coverage: uint,
    last-updated: uint
  }
)

(define-map insurance-claims
  { claim-id: uint }
  {
    market-id: uint,
    trader: principal,
    amount: uint,
    reason: (string-ascii 50),
    status: uint, ;; 0: pending, 1: approved, 2: rejected
    timestamp: uint
  }
)

;; REFERRAL SYSTEM
(define-map referral-codes
  { code: (string-ascii 20) }
  {
    referrer: principal,
    total-referrals: uint,
    total-volume: uint,
    commission-earned: uint,
    is-active: bool
  }
)

(define-map user-referrals
  { user: principal }
  {
    referrer: (optional principal),
    referred-users: uint,
    referral-rewards: uint,
    discount-tier: uint
  }
)

;; ADVANCED ORDER TYPES & STRATEGIES
(define-map advanced-orders
  { order-id: (buff 32) }
  {
    trader: principal,
    market-id: uint,
    order-type: uint, ;; 5: OCO, 6: Trailing Stop, 7: TWAP, 8: Iceberg
    primary-price: uint,
    secondary-price: (optional uint),
    trail-amount: (optional uint),
    time-in-force: uint,
    execution-params: (optional (buff 100))
  }
)

;; CROSS-MARGIN SYSTEM
(define-map cross-margin-accounts
  { user: principal }
  {
    total-collateral: uint,
    used-margin: uint,
    maintenance-margin: uint,
    available-margin: uint,
    portfolio-pnl: int,
    risk-score: uint
  }
)

;; YIELD FARMING VAULTS
(define-map yield-vaults
  { vault-id: uint }
  {
    name: (string-ascii 30),
    strategy-contract: principal,
    total-assets: uint,
    total-shares: uint,
    performance-fee: uint,
    management-fee: uint,
    is-active: bool,
    risk-level: uint
  }
)

(define-map vault-positions
  { vault-id: uint, user: principal }
  {
    shares: uint,
    deposited-amount: uint,
    entry-timestamp: uint,
    accumulated-yield: uint
  }
)

;; GOVERNANCE SYSTEM
(define-map governance-proposals
  { proposal-id: uint }
  {
    proposer: principal,
    title: (string-ascii 100),
    description: (string-ascii 500),
    proposal-type: uint,
    voting-start: uint,
    voting-end: uint,
    votes-for: uint,
    votes-against: uint,
    quorum-reached: bool,
    executed: bool
  }
)

(define-map governance-votes
  { proposal-id: uint, voter: principal }
  {
    vote: bool, ;; true for yes, false for no
    voting-power: uint,
    timestamp: uint
  }
)
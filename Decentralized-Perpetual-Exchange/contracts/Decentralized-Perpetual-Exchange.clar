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

;; PORTFOLIO ANALYTICS
(define-map portfolio-metrics
  { user: principal, period: uint } ;; period in days
  {
    total-pnl: int,
    win-rate: uint,
    sharpe-ratio: int,
    max-drawdown: uint,
    total-trades: uint,
    avg-holding-period: uint,
    risk-adjusted-return: int
  }
)

;; SOCIAL FEATURES
(define-map trader-profiles
  { trader: principal }
  {
    display-name: (string-ascii 50),
    reputation-score: uint,
    followers: uint,
    following: uint,
    public-stats: bool,
    verified: bool
  }
)

(define-map copy-trading
  { follower: principal, leader: principal }
  {
    allocation-percentage: uint,
    max-position-size: uint,
    copy-settings: (buff 50),
    performance: int,
    start-timestamp: uint
  }
)

;; RISK MANAGEMENT ENHANCEMENTS
(define-map risk-parameters
  { market-id: uint }
  {
    position-limit: uint,
    concentration-limit: uint,
    volatility-threshold: uint,
    correlation-limits: (list 10 uint),
    stress-test-scenarios: (list 5 uint)
  }
)

;; Data variables for counters
(define-data-var proposal-counter uint u0)
(define-data-var vault-counter uint u0)
(define-data-var claim-counter uint u0)

(define-private (calculate-tier (staked-amount uint))
  (if (>= staked-amount u10000000000) ;; 100 STX
    TIER_PLATINUM
    (if (>= staked-amount u5000000000) ;; 50 STX
      TIER_GOLD
      (if (>= staked-amount u1000000000) ;; 10 STX
        TIER_SILVER
        TIER_BRONZE
      )
    )
  )
)

(define-private (update-liquidity-rewards (market-id uint) (provider principal))
  (let (
    (reward-pool (unwrap! (map-get? reward-pools { market-id: market-id }) (ok true)))
    (provider-data (unwrap! (map-get? liquidity-providers { provider: provider, market-id: market-id }) (ok true)))
  )
    ;; Calculate pending rewards
    (let (
      (pending-rewards (* (get staked-amount provider-data) (get accumulated-reward-per-share reward-pool)))
    )
      (map-set liquidity-providers
        { provider: provider, market-id: market-id }
        (merge provider-data {
          accumulated-rewards: (+ (get accumulated-rewards provider-data) pending-rewards),
          reward-debt: pending-rewards
        })
      )
      (ok true)
    )
  )
)

(define-public (contribute-to-insurance (market-id uint) (amount uint))
  (let (
    (current-fund (default-to 
      { balance: u0, contribution-rate: u10, deficit-coverage: u0, last-updated: u0 }
      (map-get? insurance-fund { market-id: market-id })
    ))
  )
    (asserts! (> amount u0) ERR_INVALID_PARAMETER)
    
    (map-set insurance-fund
      { market-id: market-id }
      (merge current-fund {
        balance: (+ (get balance current-fund) amount),
        last-updated: stacks-block-height
      })
    )
    (ok true)
  )
)

(define-public (claim-insurance (market-id uint) (amount uint) (reason (string-ascii 50)))
  (let (
    (claim-id (var-get claim-counter))
    (fund (unwrap! (map-get? insurance-fund { market-id: market-id }) ERR_ORACLE_NOT_FOUND))
  )
    (asserts! (>= (get balance fund) amount) ERR_INSURANCE_FUND_INSUFFICIENT)
    
    (map-set insurance-claims
      { claim-id: claim-id }
      {
        market-id: market-id,
        trader: tx-sender,
        amount: amount,
        reason: reason,
        status: u0,
        timestamp: stacks-block-height
      }
    )
    (var-set claim-counter (+ claim-id u1))
    (ok claim-id)
  )
)


(define-public (create-referral-code (code (string-ascii 20)))
  (begin
    (asserts! (is-none (map-get? referral-codes { code: code })) ERR_DUPLICATE_ORDER_ID)
    
    (map-set referral-codes
      { code: code }
      {
        referrer: tx-sender,
        total-referrals: u0,
        total-volume: u0,
        commission-earned: u0,
        is-active: true
      }
    )
    (ok true)
  )
)


(define-public (use-referral-code (code (string-ascii 20)))
  (let (
    (referral-data (unwrap! (map-get? referral-codes { code: code }) ERR_REFERRAL_NOT_FOUND))
  )
    (asserts! (get is-active referral-data) ERR_INVALID_PARAMETER)
    
    (map-set user-referrals
      { user: tx-sender }
      {
        referrer: (some (get referrer referral-data)),
        referred-users: u0,
        referral-rewards: u0,
        discount-tier: u1
      }
    )
    (ok true)
  )
)

;; ===== YIELD VAULT FUNCTIONS =====

(define-public (create-yield-vault 
                (name (string-ascii 30))
                (strategy-contract principal)
                (performance-fee uint)
                (management-fee uint)
                (risk-level uint))
  (let (
    (vault-id (var-get vault-counter))
  )
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_NOT_AUTHORIZED)
    (asserts! (<= performance-fee u2000) ERR_INVALID_PARAMETER) ;; Max 20%
    (asserts! (<= management-fee u200) ERR_INVALID_PARAMETER) ;; Max 2%
    
    (map-set yield-vaults
      { vault-id: vault-id }
      {
        name: name,
        strategy-contract: strategy-contract,
        total-assets: u0,
        total-shares: u0,
        performance-fee: performance-fee,
        management-fee: management-fee,
        is-active: true,
        risk-level: risk-level
      }
    )
    (var-set vault-counter (+ vault-id u1))
    (ok vault-id)
  )
)

(define-public (deposit-to-vault (vault-id uint) (amount uint))
  (let (
    (vault (unwrap! (map-get? yield-vaults { vault-id: vault-id }) ERR_VAULT_NOT_FOUND))
    (shares-to-mint (if (is-eq (get total-assets vault) u0)
                      amount
                      (/ (* amount (get total-shares vault)) (get total-assets vault))))
  )
    (asserts! (get is-active vault) ERR_INVALID_PARAMETER)
    (asserts! (> amount u0) ERR_INVALID_PARAMETER)
    
    (map-set vault-positions
      { vault-id: vault-id, user: tx-sender }
      {
        shares: shares-to-mint,
        deposited-amount: amount,
        entry-timestamp: stacks-block-height,
        accumulated-yield: u0
      }
    )
    
    (map-set yield-vaults
      { vault-id: vault-id }
      (merge vault {
        total-assets: (+ (get total-assets vault) amount),
        total-shares: (+ (get total-shares vault) shares-to-mint)
      })
    )
    (ok shares-to-mint)
  )
)

(define-public (create-proposal 
                (title (string-ascii 100))
                (description (string-ascii 500))
                (proposal-type uint)
                (voting-duration uint))
  (let (
    (proposal-id (var-get proposal-counter))
  )
    (asserts! (<= voting-duration u20160) ERR_INVALID_PARAMETER) ;; Max 2 weeks
    
    (map-set governance-proposals
      { proposal-id: proposal-id }
      {
        proposer: tx-sender,
        title: title,
        description: description,
        proposal-type: proposal-type,
        voting-start: stacks-block-height,
        voting-end: (+ stacks-block-height voting-duration),
        votes-for: u0,
        votes-against: u0,
        quorum-reached: false,
        executed: false
      }
    )
    (var-set proposal-counter (+ proposal-id u1))
    (ok proposal-id)
  )
)

(define-public (vote-on-proposal (proposal-id uint) (vote bool) (voting-power uint))
  (let (
    (proposal (unwrap! (map-get? governance-proposals { proposal-id: proposal-id }) ERR_GOVERNANCE_PROPOSAL_NOT_FOUND))
  )
    (asserts! (<= stacks-block-height (get voting-end proposal)) ERR_INVALID_PARAMETER)
    (asserts! (>= stacks-block-height (get voting-start proposal)) ERR_INVALID_PARAMETER)
    
    (map-set governance-votes
      { proposal-id: proposal-id, voter: tx-sender }
      {
        vote: vote,
        voting-power: voting-power,
        timestamp: stacks-block-height
      }
    )
    
    (if vote
      (map-set governance-proposals
        { proposal-id: proposal-id }
        (merge proposal { votes-for: (+ (get votes-for proposal) voting-power) })
      )
      (map-set governance-proposals
        { proposal-id: proposal-id }
        (merge proposal { votes-against: (+ (get votes-against proposal) voting-power) })
      )
    )
    (ok true)
  )
)

(define-read-only (get-liquidity-provider-info (provider principal) (market-id uint))
  (map-get? liquidity-providers { provider: provider, market-id: market-id })
)

(define-read-only (get-insurance-fund-balance (market-id uint))
  (match (map-get? insurance-fund { market-id: market-id })
    fund (ok (get balance fund))
    ERR_ORACLE_NOT_FOUND
  )
)

(define-read-only (get-referral-stats (code (string-ascii 20)))
  (map-get? referral-codes { code: code })
)

(define-read-only (get-vault-info (vault-id uint))
  (map-get? yield-vaults { vault-id: vault-id })
)

(define-read-only (get-proposal-details (proposal-id uint))
  (map-get? governance-proposals { proposal-id: proposal-id })
)

(define-read-only (get-user-vault-position (vault-id uint) (user principal))
  (map-get? vault-positions { vault-id: vault-id, user: user })
)

(define-read-only (get-cross-margin-account (user principal))
  (map-get? cross-margin-accounts { user: user })
)

(define-read-only (get-portfolio-metrics (user principal) (period uint))
  (map-get? portfolio-metrics { user: user, period: period })
)

(define-read-only (get-trader-profile (trader principal))
  (map-get? trader-profiles { trader: trader })
)
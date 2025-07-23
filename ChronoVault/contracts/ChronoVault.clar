;; ChronoVault - Advanced time-locked digital asset vault with integrated yield generation
;; A sophisticated smart contract system for secure asset storage with multi-signature controls and DeFi yield farming

;; Error codes
(define-constant ERR-UNAUTHORIZED-ACCESS (err u100))
(define-constant ERR-VAULT-ALREADY-CONFIGURED (err u101))
(define-constant ERR-VAULT-NOT-CONFIGURED (err u102))
(define-constant ERR-TIMELOCK-STILL-ACTIVE (err u103))
(define-constant ERR-INSUFFICIENT-GUARDIAN-SIGNATURES (err u104))
(define-constant ERR-INVALID-HEIR-ADDRESS (err u105))
(define-constant ERR-TIMELOCK-ALREADY-EXPIRED (err u106))
(define-constant ERR-YIELD-POSITION-EXISTS (err u112))
(define-constant ERR-NO-ACTIVE_YIELD-POSITION (err u113))
(define-constant ERR-INSUFFICIENT-VAULT-BALANCE (err u114))

;; Core vault state variables
(define-data-var vault-owner principal tx-sender)
(define-data-var timelock-expiry uint u0)
(define-data-var guardian-threshold uint u0)
(define-data-var designated-heir (optional principal) none)
(define-data-var total-vault-balance uint u0)
(define-data-var active-signature-count uint u0)
(define-data-var current-withdrawal-round uint u0)
(define-data-var yield-system-active bool false)
(define-data-var cumulative-yield-generated uint u0)
(define-data-var annual-yield-percentage uint u5) ;; 5% APY default (adjustable by owner)

;; Storage mappings
(define-map vault-guardians principal bool)
(define-map guardian-signatures {guardian: principal, round: uint} bool)
(define-map user-asset-balances principal uint)
(define-map active-yield-stakes 
    principal 
    {staked-amount: uint, stake-start-height: uint, last-harvest-height: uint})

;; Public read-only functions for vault status
(define-read-only (get-timelock-expiry)
    (var-get timelock-expiry))

(define-read-only (get-total-vault-balance)
    (var-get total-vault-balance))

(define-read-only (get-user-asset-balance (user principal))
    (default-to u0 (map-get? user-asset-balances user)))

(define-read-only (get-current-withdrawal-round)
    (var-get current-withdrawal-round))

(define-read-only (get-active-signature-count)
    (var-get active-signature-count))

(define-read-only (is-registered-guardian (account principal))
    (default-to false (map-get? vault-guardians account)))

(define-read-only (is-vault-owner)
    (is-eq tx-sender (var-get vault-owner)))

(define-read-only (has-guardian-signed (guardian principal))
    (default-to 
        false 
        (map-get? guardian-signatures {guardian: guardian, round: (var-get current-withdrawal-round)})))

(define-read-only (get-yield-system-status)
    (var-get yield-system-active))

(define-read-only (get-cumulative-yield-generated)
    (var-get cumulative-yield-generated))

(define-read-only (get-user-yield-stake (user principal))
    (map-get? active-yield-stakes user))

;; Calculate accumulated yield for a staking position
(define-read-only (calculate-accumulated-yield (principal-amount uint) (block-duration uint))
    (let (
        (blocks-per-year u52560) ;; Approximate blocks in one year
        (yield-earned (/ (* (* principal-amount (var-get annual-yield-percentage)) block-duration) (* blocks-per-year u100))))
        yield-earned))

;; Initialize the ChronoVault system
(define-public (configure-chronovault (timelock-duration uint) (guardian-count-required uint) (heir-address (optional principal)))
    (let ((caller tx-sender))
        (asserts! (is-vault-owner) ERR-UNAUTHORIZED-ACCESS)
        (asserts! (is-eq (var-get timelock-expiry) u0) ERR-VAULT-ALREADY-CONFIGURED)
        (asserts! (> timelock-duration u0) (err u107))
        (asserts! (> guardian-count-required u0) (err u108))
        
        (var-set guardian-threshold guardian-count-required)
        (var-set designated-heir heir-address)
        (ok true)))

;; Register a new vault guardian
(define-public (register-guardian (new-guardian principal))
    (begin
        (asserts! (is-vault-owner) ERR-UNAUTHORIZED-ACCESS)
        (map-set vault-guardians new-guardian true)
        (ok true)))

;; Remove a vault guardian
(define-public (remove-guardian (guardian principal))
    (begin
        (asserts! (is-vault-owner) ERR-UNAUTHORIZED-ACCESS)
        (map-delete vault-guardians guardian)
        (ok true)))

;; Deposit STX into the ChronoVault
(define-public (deposit-assets (deposit-amount uint))
    (begin
        (asserts! (> deposit-amount u0) (err u109))
        (try! (stx-transfer? deposit-amount tx-sender (as-contract tx-sender)))
        (var-set total-vault-balance (+ (var-get total-vault-balance) deposit-amount))
        (ok true)))

;; Begin yield staking for earning passive income
(define-public (initiate-yield-staking (stake-amount uint))
    (let (
        (available-balance (var-get total-vault-balance))
        (current-stake (get-user-yield-stake tx-sender)))
        
        (asserts! (> stake-amount u0) (err u109))
        (asserts! (>= available-balance stake-amount) ERR-INSUFFICIENT-VAULT-BALANCE)
        (asserts! (is-none current-stake) ERR-YIELD-POSITION-EXISTS)
        
        (map-set active-yield-stakes 
            tx-sender 
            {staked-amount: stake-amount, 
             last-harvest-height: block-height})
        
        (var-set total-vault-balance (- available-balance stake-amount))
        (var-set yield-system-active true)
        (ok true)))

;; Harvest accumulated yield rewards
(define-public (harvest-yield-rewards)
    (let (
        (stake-info (unwrap! (get-user-yield-stake tx-sender) ERR-NO-ACTIVE_YIELD-POSITION))
        (staked-amount (get staked-amount stake-info))
        (last-harvest (get last-harvest-height stake-info))
        (blocks-elapsed (- block-height last-harvest))
        (earned-yield (calculate-accumulated-yield staked-amount blocks-elapsed)))
        
        (asserts! (> blocks-elapsed u0) ERR-NO-ACTIVE_YIELD-POSITION)
        
        (map-set active-yield-stakes
            tx-sender
            (merge stake-info {last-harvest-height: block-height}))
        
        (var-set cumulative-yield-generated (+ (var-get cumulative-yield-generated) earned-yield))
        (var-set total-vault-balance (+ (var-get total-vault-balance) earned-yield))
        (ok earned-yield)))

;; Complete yield staking and withdraw principal + final rewards
(define-public (complete-yield-staking)
    (let (
        (stake-info (unwrap! (get-user-yield-stake tx-sender) ERR-NO-ACTIVE_YIELD-POSITION))
        (staked-amount (get staked-amount stake-info))
        (last-harvest (get last-harvest-height stake-info))
        (blocks-elapsed (- block-height last-harvest))
        (final-yield (calculate-accumulated-yield staked-amount blocks-elapsed)))
        
        ;; Return original stake plus final yield
        (map-delete active-yield-stakes tx-sender)
        (var-set total-vault-balance (+ (var-get total-vault-balance) staked-amount final-yield))
        (var-set cumulative-yield-generated (+ (var-get cumulative-yield-generated) final-yield))
        (var-set yield-system-active false)
        (ok (+ staked-amount final-yield))))

;; Guardian signature for withdrawal authorization
(define-public (provide-guardian-signature)
    (begin
        (asserts! (is-registered-guardian tx-sender) ERR-UNAUTHORIZED-ACCESS)
        (asserts! (not (has-guardian-signed tx-sender)) (err u111))
        (map-set guardian-signatures 
                 {guardian: tx-sender, round: (var-get current-withdrawal-round)} 
                 true)
        (var-set active-signature-count (+ (var-get active-signature-count) u1))
        (ok true)))

;; Initiate new withdrawal authorization round
(define-public (begin-withdrawal-round)
    (begin
        (asserts! (is-vault-owner) ERR-UNAUTHORIZED-ACCESS)
        (var-set current-withdrawal-round (+ (var-get current-withdrawal-round) u1))
        (var-set active-signature-count u0)
        (ok true)))

;; Execute withdrawal from ChronoVault
(define-public (execute-withdrawal (withdrawal-amount uint))
    (let ((available-balance (var-get total-vault-balance)))
        (asserts! (>= available-balance withdrawal-amount) (err u110))
        (asserts! (or 
            (and 
                (>= block-height (var-get timelock-expiry))
                (>= (var-get active-signature-count) (var-get guardian-threshold)))
            (is-heir-emergency-withdrawal)) ERR-TIMELOCK-STILL-ACTIVE)
        
        (try! (as-contract (stx-transfer? withdrawal-amount tx-sender (var-get vault-owner))))
        (var-set total-vault-balance (- available-balance withdrawal-amount))
        (ok true)))

;; Check if heir can perform emergency withdrawal
(define-private (is-heir-emergency-withdrawal)
    (let ((current-heir (var-get designated-heir)))
        (match current-heir
            heir-principal (and 
                (is-eq tx-sender heir-principal)
                (> block-height (+ (var-get timelock-expiry) u52560)))
            false)))

;; Update designated heir
(define-public (update-designated-heir (new-heir (optional principal)))
    (begin
        (asserts! (is-vault-owner) ERR-UNAUTHORIZED-ACCESS)
        (var-set designated-heir new-heir)
        (ok true)))

;; Transfer vault ownership
(define-public (transfer-vault-ownership (new-owner principal))
    (begin
        (asserts! (is-vault-owner) ERR-UNAUTHORIZED-ACCESS)
        (var-set vault-owner new-owner)
        (ok true)))

;; Update annual yield percentage (owner only)
(define-public (adjust-yield-rate (new-percentage uint))
    (begin
        (asserts! (is-vault-owner) ERR-UNAUTHORIZED-ACCESS)
        (asserts! (<= new-percentage u100) (err u115))
        (var-set annual-yield-percentage new-percentage)
        (ok true)))
;; Contract Name: EnergyMeter
;; A pay-as-you-go decentralized energy meter
;; Users prepay STX to the contract
;; Providers withdraw based on units consumed

;; Constants and Data Vars
(define-data-var meter-id uint u0)

;; Meter struct: id, user, provider, rate (STX per unit), prepaid, consumed, active?
(define-map meters
  {id: uint}
  {user: principal, 
   provider: principal, 
   rate: uint, 
   prepaid: uint, 
   consumed: uint, 
   active: bool})

;; Errors
(define-constant ERR-NO-SUCH-METER (err u100))
(define-constant ERR-NOT-USER (err u101))
(define-constant ERR-NOT-PROVIDER (err u102))
(define-constant ERR-NOT-ACTIVE (err u103))
(define-constant ERR-INSUFFICIENT-FUNDS (err u104))
(define-constant ERR-INVALID-PARAMETERS (err u200))
(define-constant ERR-TRANSFER-FAILED (err u201))

;; Helper Functions
(define-private (is-valid-id (id uint))
  (<= id (var-get meter-id)))

;; Public Functions
;; User creates meter by prepaying STX
(define-public (create-meter (provider principal) (rate uint) (prepay uint))
  (let
    ((caller tx-sender))
    ;; Check inputs
    (asserts! (> rate u0) ERR-INVALID-PARAMETERS)
    (asserts! (> prepay u0) ERR-INVALID-PARAMETERS)
    ;; Transfer funds
    (try! (as-contract (stx-transfer? prepay caller tx-sender)))
    ;; Create meter
    (let ((new-id (+ u1 (var-get meter-id))))
      (var-set meter-id new-id)
      (ok (map-set meters {id: new-id}
            {user: caller,
             provider: provider,
             rate: rate,
             prepaid: prepay,
             consumed: u0,
             active: true})))))

;; Provider records consumption (in units), auto-withdraws STX proportionally
(define-public (record-consumption (id uint) (units uint))
  (let
    ((caller tx-sender)
     (opt-meter (map-get? meters {id: id})))
    (asserts! (is-valid-id id) ERR-NO-SUCH-METER)
    (if (is-none opt-meter)
        ERR-NO-SUCH-METER
        (let ((meter (unwrap! opt-meter ERR-NO-SUCH-METER)))
          (asserts! (is-eq (get provider meter) caller) ERR-NOT-PROVIDER)
          (asserts! (get active meter) ERR-NOT-ACTIVE)
          (asserts! (> units u0) ERR-INVALID-PARAMETERS)
          (let ((cost (* units (get rate meter))))
            (asserts! (<= cost (get prepaid meter)) ERR-INSUFFICIENT-FUNDS)
            ;; Transfer payment to provider
            (try! (as-contract (stx-transfer? cost tx-sender caller)))
            ;; Update meter state
            (ok (map-set meters {id: id}
                  {user: (get user meter),
                   provider: (get provider meter),
                   rate: (get rate meter),
                   prepaid: (- (get prepaid meter) cost),
                   consumed: (+ (get consumed meter) units),
                   active: (get active meter)})))))))

;; User tops up prepaid balance
(define-public (top-up (id uint) (amount uint))
  (let
    ((caller tx-sender)
     (opt-meter (map-get? meters {id: id})))
    (asserts! (is-valid-id id) ERR-NO-SUCH-METER)
    (if (is-none opt-meter)
        ERR-NO-SUCH-METER
        (let ((meter (unwrap! opt-meter ERR-NO-SUCH-METER)))
          (asserts! (is-eq (get user meter) caller) ERR-NOT-USER)
          (asserts! (> amount u0) ERR-INVALID-PARAMETERS)
          ;; Transfer funds
          (try! (as-contract (stx-transfer? amount caller tx-sender)))
          ;; Update meter state
          (ok (map-set meters {id: id}
                {user: (get user meter),
                 provider: (get provider meter),
                 rate: (get rate meter),
                 prepaid: (+ (get prepaid meter) amount),
                 consumed: (get consumed meter),
                 active: (get active meter)}))))))

;; User cancels meter and withdraws remaining prepaid balance
(define-public (cancel (id uint))
  (let
    ((caller tx-sender)
     (opt-meter (map-get? meters {id: id})))
    (asserts! (is-valid-id id) ERR-NO-SUCH-METER)
    (if (is-none opt-meter)
        ERR-NO-SUCH-METER
        (let ((meter (unwrap! opt-meter ERR-NO-SUCH-METER)))
          (asserts! (is-eq (get user meter) caller) ERR-NOT-USER)
          (asserts! (get active meter) ERR-NOT-ACTIVE)
          (let ((refund (get prepaid meter)))
            ;; Transfer refund to user
            (try! (as-contract (stx-transfer? refund tx-sender caller)))
            ;; Update meter state
            (ok (map-set meters {id: id}
                  {user: (get user meter),
                   provider: (get provider meter),
                   rate: (get rate meter),
                   prepaid: u0,
                   consumed: (get consumed meter),
                   active: false})))))))

;; Read Only Functions
;; View meter details
(define-read-only (get-meter (id uint))
  (if (is-valid-id id)
      (map-get? meters {id: id})
      none))
;; MediCore - Pharmaceutical Traceability Contract

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-registered (err u101))
(define-constant err-invalid-batch (err u102))
(define-constant err-unauthorized (err u103))
(define-constant err-invalid-status (err u104))
(define-constant err-invalid-expiry (err u105))
(define-constant err-duplicate-batch (err u106))

;; Data Variables
(define-data-var last-batch-id uint u0)
(define-map batch-numbers (string-ascii 20) bool)

;; Events
(define-data-var last-event-id uint u0)
(define-map events uint {
  event-type: (string-ascii 20),
  batch-id: uint,
  participant: principal,
  data: (string-ascii 50),
  timestamp: uint
})

;; Maps
(define-map participants principal 
  {
    role: (string-ascii 20),
    status: bool,
    registration-time: uint
  }
)

(define-map drug-batches uint 
  {
    manufacturer: principal,
    current-owner: principal,
    drug-name: (string-ascii 50),
    batch-number: (string-ascii 20),
    manufacture-date: uint,
    expiry-date: uint,
    status: (string-ascii 20)
  }
)

(define-map transfer-history uint (list 200 
  {
    from: principal,
    to: principal,
    timestamp: uint
  })
)

;; Private Functions
(define-private (is-registered (address principal))
  (default-to false (get status (map-get? participants address)))
)

(define-private (is-manufacturer (address principal))
  (let ((participant (map-get? participants address)))
    (if (is-some participant)
      (is-eq (get role participant) "manufacturer")
      false
    )
  )
)

(define-private (is-valid-status (status (string-ascii 20)))
  (or 
    (is-eq status "active")
    (is-eq status "recalled")
    (is-eq status "expired")
    (is-eq status "destroyed")
  )
)

(define-private (validate-batch-creation 
  (batch-number (string-ascii 20))
  (expiry-date uint))
  (begin
    (asserts! (> expiry-date block-height) err-invalid-expiry)
    (asserts! (not (default-to false (map-get? batch-numbers batch-number))) 
      err-duplicate-batch)
    (ok true)
  )
)

(define-private (emit-event 
  (event-type (string-ascii 20))
  (batch-id uint)
  (data (string-ascii 50)))
  (let ((event-id (+ (var-get last-event-id) u1)))
    (var-set last-event-id event-id)
    (map-set events event-id {
      event-type: event-type,
      batch-id: batch-id,
      participant: tx-sender,
      data: data,
      timestamp: block-height
    })
    (ok event-id)
  )
)

;; Public Functions
(define-public (register-participant (role (string-ascii 20)))
  (begin
    (asserts! (or (is-eq tx-sender contract-owner) 
              (is-registered tx-sender)) 
          err-unauthorized)
    (ok (map-set participants tx-sender
      {
        role: role,
        status: true,
        registration-time: block-height
      }))
  )
)

(define-public (create-batch 
  (drug-name (string-ascii 50)) 
  (batch-number (string-ascii 20))
  (expiry-date uint))
  (let ((batch-id (+ (var-get last-batch-id) u1)))
    (asserts! (is-manufacturer tx-sender) err-unauthorized)
    (try! (validate-batch-creation batch-number expiry-date))
    (var-set last-batch-id batch-id)
    (map-set batch-numbers batch-number true)
    (map-set drug-batches batch-id
      {
        manufacturer: tx-sender,
        current-owner: tx-sender,
        drug-name: drug-name,
        batch-number: batch-number,
        manufacture-date: block-height,
        expiry-date: expiry-date,
        status: "active"
      })
    (map-set transfer-history batch-id (list {
      from: tx-sender,
      to: tx-sender,
      timestamp: block-height
    }))
    (try! (emit-event "batch-created" batch-id drug-name))
    (ok batch-id)
  )
)

;; [Rest of the contract remains unchanged...]

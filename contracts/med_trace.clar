;; MediCore - Pharmaceutical Traceability Contract

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-registered (err u101))
(define-constant err-invalid-batch (err u102))
(define-constant err-unauthorized (err u103))
(define-constant err-invalid-status (err u104))

;; Data Variables
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

;; Data Variables
(define-data-var last-batch-id uint u0)

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

(define-public (create-batch (drug-name (string-ascii 50)) 
                         (batch-number (string-ascii 20))
                         (expiry-date uint))
  (let ((batch-id (+ (var-get last-batch-id) u1)))
    (asserts! (is-manufacturer tx-sender) err-unauthorized)
    (var-set last-batch-id batch-id)
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
    (ok batch-id)
  )
)

(define-public (transfer-batch (batch-id uint) (recipient principal))
  (let ((batch (map-get? drug-batches batch-id))
        (history (map-get? transfer-history batch-id)))
    (asserts! (and (is-some batch) 
               (is-registered recipient)) err-invalid-batch)
    (asserts! (is-eq (get current-owner batch) tx-sender) err-unauthorized)
    (asserts! (is-eq (get status batch) "active") err-invalid-batch)
    (map-set drug-batches batch-id 
      (merge batch {current-owner: recipient}))
    (map-set transfer-history batch-id 
      (append (default-to (list) history)
        {
          from: tx-sender,
          to: recipient,
          timestamp: block-height
        }))
    (ok true)
  )
)

(define-public (update-batch-status (batch-id uint) (new-status (string-ascii 20)))
  (let ((batch (map-get? drug-batches batch-id)))
    (asserts! (is-some batch) err-invalid-batch)
    (asserts! (is-eq (get current-owner batch) tx-sender) err-unauthorized)
    (asserts! (is-valid-status new-status) err-invalid-status)
    (ok (map-set drug-batches batch-id 
      (merge batch {status: new-status})))
  )
)

;; Read-only Functions
(define-read-only (get-batch-info (batch-id uint))
  (ok (map-get? drug-batches batch-id))
)

(define-read-only (get-batch-history (batch-id uint))
  (ok (map-get? transfer-history batch-id))
)

(define-read-only (get-participant-info (address principal))
  (ok (map-get? participants address))
)

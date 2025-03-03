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
(define-constant err-invalid-batch-format (err u107))
(define-constant err-transfer-history-full (err u108))

;; Data Variables
(define-data-var last-batch-id uint u0)
(define-map batch-numbers (string-ascii 20) bool)
(define-data-var last-event-id uint u0)

;; Event pruning threshold
(define-constant max-events u1000)
(define-constant max-transfers u200)

;; Private Functions
(define-private (is-valid-batch-format (batch-number (string-ascii 20)))
  (let ((len (len batch-number)))
    (and
      (>= len u6)
      (<= len u20)
      (is-eq (slice batch-number 0 4) "BATCH")
    )
  )
)

(define-private (validate-batch-creation 
  (batch-number (string-ascii 20))
  (expiry-date uint))
  (begin
    (asserts! (> expiry-date block-height) err-invalid-expiry)
    (asserts! (is-valid-batch-format batch-number) err-invalid-batch-format)
    (asserts! (not (default-to false (map-get? batch-numbers batch-number))) 
      err-duplicate-batch)
    (ok true)
  )
)

;; [Rest of the original contract code remains unchanged...]

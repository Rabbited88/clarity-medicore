# MediCore - Pharmaceutical Traceability System

A blockchain-based solution for tracking pharmaceutical products through the supply chain. This system enables:

- Registration of manufacturers, distributors, and pharmacies
- Logging of drug batches with unique identifiers
- Tracking of drug transfers between supply chain participants
- Verification of drug authenticity and chain of custody
- Management of batch status lifecycle

## Features
- Secure participant registration
- Batch creation and tracking
- Transfer logging with timestamps
- Chain of custody verification
- Status management for drug batches (active, recalled, expired, destroyed)
- Transfer restrictions based on batch status

## Usage
The contract provides functions for:
- Registering supply chain participants
- Creating new drug batches
- Transferring ownership of batches
- Verifying drug authenticity
- Checking batch history
- Updating batch status throughout its lifecycle

### Batch Status Lifecycle
- active: Default status for new batches
- recalled: For batches that need to be removed from circulation
- expired: For batches past their expiration date
- destroyed: For batches that have been properly disposed of

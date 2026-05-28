module vanishvault::vanishvault {
    use sui::object::{Self, UID};
    use sui::tx_context::{Self, TxContext};
    use sui::transfer;
    use sui::clock::{Self, Clock};
    use std::string::String;

    /// Represents an encrypted file stored on Walrus
    public struct EncryptedFile has key, store {
        id: UID,
        owner: address,
        walrus_path: String,
        content_hash: vector<u8>,
        created_at: u64,
        destruction_time: u64,
        is_destroyed: bool,
        access_key: vector<u8>,
    }

    /// Event emitted when a file is uploaded
    public struct FileUploaded has copy, drop {
        file_id: object::ID,
        owner: address,
        created_at: u64,
        destruction_time: u64,
    }

    /// Event emitted when a file is destroyed
    public struct FileDestroyed has copy, drop {
        file_id: object::ID,
        destroyed_at: u64,
    }

    /// Event emitted when a file is accessed
    public struct FileAccessed has copy, drop {
        file_id: object::ID,
        accessed_by: address,
        accessed_at: u64,
    }

    const TWENTYFOUR_HOURS: u64 = 86400000; // milliseconds
    const EFileNotFound: u64 = 1;
    const EFileAlreadyDestroyed: u64 = 2;
    const EUnauthorizedAccess: u64 = 3;
    const EDestructionTimeNotReached: u64 = 4;

    /// Upload an encrypted file to Walrus
    public fun upload_file(
        walrus_path: String,
        content_hash: vector<u8>,
        access_key: vector<u8>,
        clock: &Clock,
        ctx: &mut TxContext,
    ): EncryptedFile {
        let now = clock::timestamp_ms(clock);
        let destruction_time = now + TWENTYFOUR_HOURS;

        let file = EncryptedFile {
            id: object::new(ctx),
            owner: tx_context::sender(ctx),
            walrus_path,
            content_hash,
            created_at: now,
            destruction_time,
            is_destroyed: false,
            access_key,
        };

        let file_id = object::id(&file);
        transfer::share_object(file);

        sui::event::emit(FileUploaded {
            file_id,
            owner: tx_context::sender(ctx),
            created_at: now,
            destruction_time,
        });

        file
    }

    /// Retrieve access to an encrypted file
    public fun retrieve_file(
        file: &EncryptedFile,
        clock: &Clock,
        ctx: &TxContext,
    ): (String, vector<u8>) {
        assert!(!file.is_destroyed, EFileAlreadyDestroyed);
        assert!(file.owner == tx_context::sender(ctx), EUnauthorizedAccess);

        let now = clock::timestamp_ms(clock);
        assert!(now <= file.destruction_time, EDestructionTimeNotReached);

        sui::event::emit(FileAccessed {
            file_id: object::id(file),
            accessed_by: tx_context::sender(ctx),
            accessed_at: now,
        });

        (file.walrus_path, file.access_key)
    }

    /// Force destroy a file after 24 hours
    public fun destroy_file(
        file: &mut EncryptedFile,
        clock: &Clock,
        _ctx: &TxContext,
    ) {
        assert!(!file.is_destroyed, EFileAlreadyDestroyed);

        let now = clock::timestamp_ms(clock);
        assert!(now >= file.destruction_time, EDestructionTimeNotReached);

        file.is_destroyed = true;

        sui::event::emit(FileDestroyed {
            file_id: object::id(file),
            destroyed_at: now,
        });
    }

    /// Query file status
    public fun get_file_info(file: &EncryptedFile): (address, u64, u64, bool) {
        (file.owner, file.created_at, file.destruction_time, file.is_destroyed)
    }

    /// Check if file can be destroyed
    public fun can_destroy(file: &EncryptedFile, clock: &Clock): bool {
        !file.is_destroyed && clock::timestamp_ms(clock) >= file.destruction_time
    }

    /// Get remaining time until destruction (in milliseconds)
    public fun time_until_destruction(file: &EncryptedFile, clock: &Clock): u64 {
        let now = clock::timestamp_ms(clock);
        if (now >= file.destruction_time) {
            0
        } else {
            file.destruction_time - now
        }
    }
}

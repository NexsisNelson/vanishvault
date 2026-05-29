module vanishvault::vanishvault {
    use sui::object::{Self, UID};
    use sui::tx_context::{Self, TxContext};
    use sui::transfer;
    use sui::clock::{Self, Clock};

    /// DataRoom: Stores encrypted file metadata with 24-hour countdown timer
    /// The creator can always delete it, but anyone can delete after expiration
    public struct DataRoom has key {
        id: UID,
        creator: address,
        receiver: address,
        walrus_blob_id: u256,
        created_at: u64,
        expires_at: u64,
    }

    /// Event: Emitted when a new DataRoom is created
    public struct RoomCreated has copy, drop {
        room_id: object::ID,
        creator: address,
        receiver: address,
        created_at: u64,
        expires_at: u64,
    }

    /// Event: Emitted when a DataRoom is destroyed
    public struct RoomDestroyed has copy, drop {
        room_id: object::ID,
        destroyed_at: u64,
    }

    const TWENTYFOUR_HOURS_MS: u64 = 86400000; // 24 hours in milliseconds
    const EUnauthorizedAccess: u64 = 1;
    const EDataRoomExpired: u64 = 2;

    /// Entry function: Create a new DataRoom
    /// Called by the uploader's frontend transaction.
    /// Sets expires_at = current_time + 24 hours
    public entry fun create_room(
        walrus_blob_id: u256,
        receiver: address,
        clock: &Clock,
        ctx: &mut TxContext,
    ): DataRoom {
        let now = clock::timestamp_ms(clock);
        let expires_at = now + TWENTYFOUR_HOURS_MS;

        let room = DataRoom {
            id: object::new(ctx),
            creator: tx_context::sender(ctx),
            receiver,
            walrus_blob_id,
            created_at: now,
            expires_at,
        };

        let room_id = object::id(&room);

        // Note: not sharing the object here so the caller receives the DataRoom
        // (tests and callers expect ownership of the created object)

        sui::event::emit(RoomCreated {
            room_id,
            creator: tx_context::sender(ctx),
            receiver,
            created_at: now,
            expires_at,
        });

        room
    }

    /// Read-only verification function
    /// Returns the Walrus blob_id only if:
    /// 1. Current time is BEFORE expires_at
    /// 2. Caller address matches the receiver address
    /// Aborts otherwise.
    public fun get_blob_id(room: &DataRoom, clock: &Clock, ctx: &TxContext): u256 {
        let now = clock::timestamp_ms(clock);
        
        // Check if room has expired
        assert!(now < room.expires_at, EDataRoomExpired);
        
        // Check if caller is authorized receiver
        assert!(tx_context::sender(ctx) == room.receiver, EUnauthorizedAccess);

        room.walrus_blob_id
    }

    /// Entry function: Destroy and expire a DataRoom
    /// Can be called by:
    /// 1. The creator at any time, OR
    /// 2. Anyone if the room has expired (automated cleanup)
    public entry fun destroy_and_expire(
        room: DataRoom,
        clock: &Clock,
        ctx: &TxContext,
    ) {
        let now = clock::timestamp_ms(clock);
        let caller = tx_context::sender(ctx);

        // Check: either caller is creator, or room has expired
        let is_creator = caller == room.creator;
        let has_expired = now >= room.expires_at;

        assert!(is_creator || has_expired, EUnauthorizedAccess);

        let room_id = object::id(&room);
        let DataRoom { id, creator: _, receiver: _, walrus_blob_id: _, created_at: _, expires_at: _ } = room;
        object::delete(id);

        sui::event::emit(RoomDestroyed {
            room_id,
            destroyed_at: now,
        });
    }

    /// Getter: Check if room has expired
    public fun is_expired(room: &DataRoom, clock: &Clock): bool {
        clock::timestamp_ms(clock) >= room.expires_at
    }

    /// Getter: Get remaining time until expiration (in milliseconds)
    public fun time_until_expiration(room: &DataRoom, clock: &Clock): u64 {
        let now = clock::timestamp_ms(clock);
        if (now >= room.expires_at) {
            0
        } else {
            room.expires_at - now
        }
    }

    /// Getter: Check room info
    public fun get_room_info(room: &DataRoom): (address, address, u64, u64) {
        (room.creator, room.receiver, room.created_at, room.expires_at)
    }

    /// Test helper: Consume a DataRoom by transferring it to `recipient`.
    /// This allows test code to properly consume the resource.
    public fun consume_room(room: DataRoom, recipient: address) {
        transfer::transfer(room, recipient);
    }
}

#[test_only]
module vanishvault::vanishvault_tests {
    use sui::test_scenario;
    use sui::clock;
    use sui::transfer;
    use vanishvault::vanishvault::{Self, DataRoom};

    #[test]
    fun test_create_room_and_get_blob() {
        let sender = @0x1;
        let mut scenario = test_scenario::begin(sender);

        let _ = test_scenario::next_tx(&mut scenario, sender);
        let ctx = test_scenario::ctx(&mut scenario);
        let mut clock = clock::create_for_testing(ctx);

        let walrus_blob_id = 1u256;
        let receiver = sender;

        let room = vanishvault::create_room(
            walrus_blob_id,
            receiver,
            &clock,
            test_scenario::ctx(&mut scenario),
        );

        let (creator, receiver_ret, created_at, expires_at) =
            vanishvault::get_room_info(&room);

        assert!(creator == sender, 0);
        assert!(receiver_ret == receiver, 1);
        assert!(expires_at > created_at, 2);
        assert!(!vanishvault::is_expired(&room, &clock), 3);

        let returned_blob_id =
            vanishvault::get_blob_id(&room, &clock, test_scenario::ctx(&mut scenario));
        assert!(returned_blob_id == walrus_blob_id, 4);

        clock::destroy_for_testing(clock);
        vanishvault::consume_room(room, sender);
        test_scenario::end(scenario);
    }

    #[test]
    #[expected_failure(abort_code = 2)]
    fun test_get_blob_id_fails_after_expiration() {
        let sender = @0x1;
        let mut scenario = test_scenario::begin(sender);

        let _ = test_scenario::next_tx(&mut scenario, sender);
        let ctx = test_scenario::ctx(&mut scenario);
        let mut clock = clock::create_for_testing(ctx);

        let walrus_blob_id = 2u256;
        let receiver = sender;

        let room = vanishvault::create_room(
            walrus_blob_id,
            receiver,
            &clock,
            test_scenario::ctx(&mut scenario),
        );

        let ts = clock::timestamp_ms(&clock);
        clock::set_for_testing(&mut clock, ts + 86400001);

        let _ = vanishvault::get_blob_id(&room, &clock, test_scenario::ctx(&mut scenario));

        clock::destroy_for_testing(clock);
        vanishvault::consume_room(room, sender);
        test_scenario::end(scenario);
    }

    #[test]
    fun test_time_until_expiration() {
        let sender = @0x1;
        let mut scenario = test_scenario::begin(sender);

        let _ = test_scenario::next_tx(&mut scenario, sender);
        let ctx = test_scenario::ctx(&mut scenario);
        let mut clock = clock::create_for_testing(ctx);

        let walrus_blob_id = 3u256;
        let receiver = sender;

        let room = vanishvault::create_room(
            walrus_blob_id,
            receiver,
            &clock,
            test_scenario::ctx(&mut scenario),
        );

        let time_until = vanishvault::time_until_expiration(&room, &clock);
        assert!(time_until > 0, 0);
        assert!(time_until <= 86400000, 1);

        clock::destroy_for_testing(clock);
        vanishvault::consume_room(room, sender);
        test_scenario::end(scenario);
    }

    #[test]
    fun test_destroy_and_expire_after_24_hours() {
        let sender = @0x1;
        let mut scenario = test_scenario::begin(sender);

        let _ = test_scenario::next_tx(&mut scenario, sender);
        let ctx = test_scenario::ctx(&mut scenario);
        let mut clock = clock::create_for_testing(ctx);

        let walrus_blob_id = 4u256;
        let receiver = sender;

        let room = vanishvault::create_room(
            walrus_blob_id,
            receiver,
            &clock,
            test_scenario::ctx(&mut scenario),
        );

        let ts = clock::timestamp_ms(&clock);
        clock::set_for_testing(&mut clock, ts + 86400001);

        vanishvault::destroy_and_expire(room, &clock, test_scenario::ctx(&mut scenario));

        clock::destroy_for_testing(clock);
        test_scenario::end(scenario);
    }
}

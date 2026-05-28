#[test_only]
module vanishvault::vanishvault_tests {
    use sui::test_scenario;
    use sui::clock;
    use vanishvault::vanishvault::{Self, EncryptedFile};
    use std::string::utf8;

    #[test]
    fun test_upload_file() {
        let sender = @0x1;
        let mut scenario = test_scenario::begin(sender);

        let tx = test_scenario::next_tx(&mut scenario, sender);
        let mut clock = clock::create_for_testing(tx);

        // Create test data
        let walrus_path = utf8(b"blob_123456");
        let content_hash = vector[1, 2, 3, 4, 5];
        let access_key = vector[10, 20, 30, 40, 50];

        // Upload file
        let file = vanishvault::upload_file(
            walrus_path,
            content_hash,
            access_key,
            &clock,
            test_scenario::ctx(&mut scenario),
        );

        // Verify file properties
        let (owner, created_at, destruction_time, is_destroyed) = vanishvault::get_file_info(&file);
        
        assert!(owner == sender, 0);
        assert!(!is_destroyed, 1);
        assert!(destruction_time > created_at, 2);
        
        clock::destroy_for_testing(clock);
        test_scenario::end(scenario);
    }

    #[test]
    fun test_retrieve_file_before_destruction() {
        let sender = @0x1;
        let mut scenario = test_scenario::begin(sender);

        let tx = test_scenario::next_tx(&mut scenario, sender);
        let mut clock = clock::create_for_testing(tx);

        let walrus_path = utf8(b"blob_test");
        let content_hash = vector[1, 2, 3];
        let access_key = vector[10, 20, 30];

        let mut file = vanishvault::upload_file(
            walrus_path,
            content_hash,
            access_key,
            &clock,
            test_scenario::ctx(&mut scenario),
        );

        // Should be able to retrieve file before destruction
        let (path, key) = vanishvault::retrieve_file(
            &file,
            &clock,
            test_scenario::ctx(&mut scenario),
        );

        assert!(path == walrus_path, 0);
        
        clock::destroy_for_testing(clock);
        test_scenario::end(scenario);
    }

    #[test]
    #[expected_failure(abort_code = 2)]
    fun test_cannot_retrieve_destroyed_file() {
        let sender = @0x1;
        let mut scenario = test_scenario::begin(sender);

        let tx = test_scenario::next_tx(&mut scenario, sender);
        let mut clock = clock::create_for_testing(tx);

        let walrus_path = utf8(b"blob_destroyed");
        let content_hash = vector[1, 2, 3];
        let access_key = vector[10, 20, 30];

        let mut file = vanishvault::upload_file(
            walrus_path,
            content_hash,
            access_key,
            &clock,
            test_scenario::ctx(&mut scenario),
        );

        // Move clock forward 24+ hours
        clock::set_for_testing(&mut clock, clock::timestamp_ms(&clock) + 86400001);

        // Destroy file
        vanishvault::destroy_file(&mut file, &clock, test_scenario::ctx(&mut scenario));

        // Should fail to retrieve
        let (_, _) = vanishvault::retrieve_file(
            &file,
            &clock,
            test_scenario::ctx(&mut scenario),
        );

        clock::destroy_for_testing(clock);
        test_scenario::end(scenario);
    }

    #[test]
    fun test_destruction_timer() {
        let sender = @0x1;
        let mut scenario = test_scenario::begin(sender);

        let tx = test_scenario::next_tx(&mut scenario, sender);
        let mut clock = clock::create_for_testing(tx);

        let walrus_path = utf8(b"blob_timer");
        let content_hash = vector[1, 2, 3];
        let access_key = vector[10, 20, 30];

        let file = vanishvault::upload_file(
            walrus_path,
            content_hash,
            access_key,
            &clock,
            test_scenario::ctx(&mut scenario),
        );

        // Check time until destruction
        let time_until = vanishvault::time_until_destruction(&file, &clock);
        assert!(time_until > 0, 0);
        assert!(time_until <= 86400000, 1); // 24 hours in milliseconds

        clock::destroy_for_testing(clock);
        test_scenario::end(scenario);
    }

    #[test]
    fun test_can_destroy_after_24_hours() {
        let sender = @0x1;
        let mut scenario = test_scenario::begin(sender);

        let tx = test_scenario::next_tx(&mut scenario, sender);
        let mut clock = clock::create_for_testing(tx);

        let walrus_path = utf8(b"blob_can_destroy");
        let content_hash = vector[1, 2, 3];
        let access_key = vector[10, 20, 30];

        let file = vanishvault::upload_file(
            walrus_path,
            content_hash,
            access_key,
            &clock,
            test_scenario::ctx(&mut scenario),
        );

        // Initially cannot destroy
        assert!(!vanishvault::can_destroy(&file, &clock), 0);

        // Move clock forward 24+ hours
        clock::set_for_testing(&mut clock, clock::timestamp_ms(&clock) + 86400001);

        // Now should be able to destroy
        assert!(vanishvault::can_destroy(&file, &clock), 1);

        clock::destroy_for_testing(clock);
        test_scenario::end(scenario);
    }
}

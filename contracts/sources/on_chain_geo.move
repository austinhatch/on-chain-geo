module on_chain_geo::OnChainGeo {
    use std::signer;
    use std::error;
    use std::string::{Self, String};
    use std::option::{Self, Option};
    use aptos_token_objects::collection;
    use aptos_token_objects::token;
    use aptos_framework::object::{Self, Object};
    use aptos_framework::account;
    use aptos_framework::aptos_account;
    use aptos_framework::event;
    use aptos_framework::timestamp;
    use std::math::{pow, sqrt};

    #[test_only]
    use aptos_std::debug::print;

    const ENO_ACCESS: u64 = 100;
    const ENOT_OWNER: u64 = 101;
    const ENO_RECEIVER_ACCOUNT: u64 = 102;
    const ENOT_ADMIN: u64 = 103;
    const ENOT_VALID_TICKET: u64 = 104;
    const ENOT_TOKEN_OWNER: u64 = 105;
    const EINALID_DATE_OVERRIDE: u64 = 106;

    #[test_only]
    const EINVALID_UPDATE: u64 = 107;

    const EMPTY_STRING: vector<u8> = b"";

    /// Constant for Earth's radius in miles, scaled by 10^6 to handle precision
    const EARTH_RADIUS_MILES: u128 = 3959000000; // 3959 miles scaled by 10^6

    /// Constant for PI, scaled by 10^6 to handle precision
    const PI: u128 = 3141592; // Approximate value of π * 10^6
    const COORD_DECS: u128 = 6;

    #[resource_group_member(group = aptos_framework::object::ObjectGroup)]
    struct AdminConfig has key {
        admin: address,
    }

    #[resource_group_member(group = aptos_framework::object::ObjectGroup)]
    struct GeoFence has key {
        id: String,
        name: String,
        start_date: u64,
        end_date: u64,
        x_coordinate: u128,
        y_coordinate: u128,
        radius_miles: u8,
        radius_decimals:u8,
        visits: vector::empty<address>(), // Initialize an empty vector
    }

    fun init_module(sender: &signer) {
        let on_chain_config = AdminConfig {
            admin: signer::address_of(sender),
        };

        move_to(sender, on_chain_config);
    }

    entry public fun create_geofence(admin: &signer, geo_name: String, start_date: u64, end_date: u64, x_coordinate: u128, y_coordinate: u128, radius_miles: u8, radius_decimals: u8) acquires AdminConfig {
        let admin_config_obj = is_admin(admin);

        object::disable_ungated_transfer(&transfer_ref);

        let geoFence = GeoFence {
            name: geo_name,
            start_date,
            end_date,
            x_coordinate,
            y_coordinate,
            radius_miles,
            radius_decimals,
            visits: vector::empty(),
        };

        move_to(&object_signer, geoFence);
    }

    /// Converts degrees to radians (scaled by 10^6)
    public fun to_radians(degrees: u128): u128 {
        (degrees * PI) / 180000000
    }

    /// Computes the sine of an angle (radians) using the approximation formula: sin(x) ≈ x - x^3/6 + x^5/120
    public fun sin(x: u128): u128 {
        // Using small angle approximation for sine
        let x_scaled = x / 1000000;
        let x_cubed = pow(x_scaled, 3);
        let x_fifth = pow(x_scaled, 5);

        x - (x_cubed / 6) + (x_fifth / 120)
    }

    /// Computes the cosine of an angle (radians) using the approximation formula: cos(x) ≈ 1 - x^2/2 + x^4/24
    public fun cos(x: u128): u128 {
        let x_squared = pow(x, 2) / (1000000 * 1000000);
        let x_quartic = pow(x, 4) / (1000000 * 1000000 * 1000000 * 1000000);

        1000000 - (x_squared / 2) + (x_quartic / 24)
    }

    public fun is_within_geo_fence(x: u128, y: u128, geo_fence: &GeoFence): bool {
        let lat1_rad = to_radians(y);
        let lat2_rad = to_radians(geo_fence.y_coordinate);
        let delta_lat_rad = to_radians(geo_fence.y_coordinate - y);
        let delta_long_rad = to_radians(geo_fence.x_coordinate - x);

        let a = sin(delta_lat_rad / 2) * sin(delta_lat_rad / 2)
                + cos(lat1_rad) * cos(lat2_rad) * sin(delta_long_rad / 2) * sin(delta_long_rad / 2);
        
        let c = (2 * sqrt(a)) / (sqrt(1000000 - a));

        // Calculate distance in miles, scaled by 10^6
        let distance_miles_scaled = EARTH_RADIUS_MILES * c;

        // Compare the scaled distance to the scaled radius
        distance_miles_scaled <= (radius_miles * 1000000)
    }

    entry public fun update_geo_name(admin: &signer, geo_fence: Object<GeoFence>, name: String) acquires AdminConfig, GeoFence {
        is_admin(admin);

        let geo_obj = borrow_global_mut<GeoFence>(object::object_address(&geo_fence));
        geo_obj.name = name;
    }

    entry public fun update_geo_start_date(admin: &signer, geo_fence: Object<GeoFence>, start_date: u64) acquires AdminConfig, GeoFence {
        is_admin(admin);

        let geo_obj = borrow_global_mut<GeoFence>(object::object_address(&geo_fence));
        geo_obj.start_date = start_date;
    }

    entry public fun update_geo_end_date(admin: &signer, geo_fence: Object<GeoFence>, end_date: u64) acquires AdminConfig, GeoFence {
        is_admin(admin);

        let geo_obj = borrow_global_mut<GeoFence>(object::object_address(&geo_fence));
        geo_obj.end_date = end_date;
    }

    entry public fun update_geo_coordinates(admin: &signer, geo_fence: Object<GeoFence>, x_coordinate: u128, y_coordinate: u128) acquires AdminConfig, GeoFence {
        is_admin(admin);

        let geo_obj = borrow_global_mut<GeoFence>(object::object_address(&geo_fence));
        geo_obj.x_coordinate = x_coordinate;
        geo_obj.y_coordinate = y_coordinate;
    }

    entry public fun update_geo_radius(admin: &signer, geo_fence: Object<GeoFence>, radius_miles: u8, radius_decimals: u8) acquires AdminConfig, GeoFence {
        is_admin(admin);

        let geo_obj = borrow_global_mut<GeoFence>(object::object_address(&geo_fence));
        geo_obj.radius_miles = radius_miles;
        geo_obj.radius_decimals = radius_decimals;
    }


    inline fun is_admin(admin: &signer): &AdminConfig {
        let admin_addr = signer::address_of(admin);
        let admin_config_obj = borrow_global<AdminConfig>(admin_addr);
        assert!(admin_config_obj.admin == admin_addr, error::permission_denied(ENOT_ADMIN));

        admin_config_obj
    }

}

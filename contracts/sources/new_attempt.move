module my_management_addr::on_chain_geo {
    use std::string::{Self, String};
    use std::math128::{pow, sqrt};
    use aptos_framework::object::{Self, Object};
    use std::option::{Self};
    use aptos_token_objects::collection;
    use aptos_token_objects::token;
    use aptos_framework::timestamp; // Import the Timestamp module
    use std::signer;

    struct Coordinate has store, copy, drop {
        value: u128, // Absolute value with 8 decimal places
        is_negative: bool, // Sign bit
    }

    #[resource_group_member(group = aptos_framework::object::ObjectGroup)]
    struct GeoFence has key {
        name: String,
        start_date: u64,
        end_date: u64,
        longitude_coordinate: Coordinate, // Updated to use Coordinate struct
        latitude_coordinate: Coordinate,  // Updated to use Coordinate struct
        radius_miles: u128,               // Fixed-point with 8 decimals
        mutator_ref: collection::MutatorRef,
        uri: String,
        delete_ref: object::DeleteRef,
    }
    const E_NOT_AUTHORIZED: u64 = 1;
    const EMPTY_STRING: vector<u8> = b"";
    const DECIMALS: u128 = 100000000; // 8 decimal places

    public entry fun create_geofence(
        account: &signer, 
        name: String, 
        start_date: u64, 
        end_date: u64, 
        longitude_value: u128, // Absolute value with 8 decimals
        longitude_is_negative: bool, // Sign bit
        latitude_value: u128,  // Absolute value with 8 decimals
        latitude_is_negative: bool,  // Sign bit
        radius_miles: u128,          // Fixed-point with 8 decimals
        uri: String
    )  {
        let longitude_coordinate = Coordinate { value: longitude_value, is_negative: longitude_is_negative };
        let latitude_coordinate = Coordinate { value: latitude_value, is_negative: latitude_is_negative };

        let collection_constructor_ref = collection::create_unlimited_collection(
            account,
            string::utf8(EMPTY_STRING),
            name,
            option::none(),
            uri,
        );
        let object_signer = object::generate_signer(&collection_constructor_ref);
        let mutator_ref = collection::generate_mutator_ref(&collection_constructor_ref);
        let delete_ref = object::generate_delete_ref(&collection_constructor_ref);

        let new_geofence = GeoFence {
            name,
            start_date,
            end_date,
            longitude_coordinate,
            latitude_coordinate,
            radius_miles,
            mutator_ref,
            uri,
            delete_ref,
        };

        move_to(&object_signer, new_geofence);
    }

    public entry fun is_within_geo(
        admin: &signer, 
        geofence: Object<GeoFence>, 
        longitude_value: u128, // Absolute value with 8 decimals
        longitude_is_negative: bool, // Sign bit
        latitude_value: u128,  // Absolute value with 8 decimals
        latitude_is_negative: bool,  // Sign bit
        ticket_id: String
    ) acquires GeoFence {
        let longitude = Coordinate { value: longitude_value, is_negative: longitude_is_negative };
        let latitude = Coordinate { value: latitude_value, is_negative: latitude_is_negative };

        let geofence_obj = borrow_global<GeoFence>(object::object_address(&geofence));
        let within_geo = Self::haversine_distance(
            geofence_obj.latitude_coordinate,
            geofence_obj.longitude_coordinate,
            latitude,
            longitude
        ) <= geofence_obj.radius_miles;

        let current_time = timestamp::now_seconds();

        if (within_geo && current_time >= geofence_obj.start_date && current_time <= geofence_obj.end_date) {
            // Mint a token to the signer
            token::create_named_token(admin, geofence_obj.name, string::utf8(EMPTY_STRING), ticket_id, option::none(), geofence_obj.uri);
        }
    }

    // Haversine formula to calculate the distance between two points on the Earth's surface
    fun haversine_distance(lat1: Coordinate, lon1: Coordinate, lat2: Coordinate, lon2: Coordinate): u128 {
        let radius_of_earth: u128 = 637100000000; // Radius of the Earth in meters (fixed-point with 8 decimals)
        let dlat = Self::to_radians(Self::coordinate_diff(lat2, lat1));
        let dlon = Self::to_radians(Self::coordinate_diff(lon2, lon1));
        let a = pow(sin(dlat / 2 / DECIMALS), 2) + cos(Self::to_radians(Self::coordinate_to_u128(lat1)) / DECIMALS) * cos(Self::to_radians(Self::coordinate_to_u128(lat2)) / DECIMALS) * pow(sin(dlon / 2 / DECIMALS), 2);
        let c = 2 * atan2(sqrt(a), sqrt(DECIMALS * DECIMALS - a));
        return radius_of_earth * c / DECIMALS
    }

    // Convert degrees to radians
    fun to_radians(degrees: u128): u128 {
        let pi: u128 = 314159265; // Approximation of pi (fixed-point with 8 decimals)
        return degrees * pi / 180000000
    }

    // Sine function approximation using Taylor series
    fun sin(x: u128): u128 {
        let x3 = pow(x, 3) / DECIMALS / DECIMALS;
        let x5 = pow(x, 5) / DECIMALS / DECIMALS / DECIMALS;
        let x7 = pow(x, 7) / DECIMALS / DECIMALS / DECIMALS / DECIMALS;
        return x - x3 / 6 + x5 / 120 - x7 / 5040
    }

    // Cosine function approximation using Taylor series
    fun cos(x: u128): u128 {
        let x2 = pow(x, 2) / DECIMALS;
        let x4 = pow(x, 4) / DECIMALS / DECIMALS;
        let x6 = pow(x, 6) / DECIMALS / DECIMALS / DECIMALS;
        return DECIMALS - x2 / 2 + x4 / 24 - x6 / 720
    }

    // Arctangent function approximation using Taylor series
    fun atan2(y: u128, x: u128): u128 {
        // Simple approximation for atan2
        if (x > y) {
            return y * DECIMALS / x
        } else {
            return x * DECIMALS / y
        }
    }

    // Helper function to calculate the difference between two coordinates
    fun coordinate_diff(coord1: Coordinate, coord2: Coordinate): u128 {
        let value1 = if (coord1.is_negative) { 0 - coord1.value } else { coord1.value };
        let value2 = if (coord2.is_negative) { 0 - coord2.value } else { coord2.value };
        return if (value1 > value2) { value1 - value2 } else { value2 - value1 }
    }

    // Helper function to convert a Coordinate to u128
    fun coordinate_to_u128(coord: Coordinate): u128 {
        return if (coord.is_negative) { 0 - coord.value } else { coord.value }
    }

       // Function to destroy the GeoFence object
    public entry fun destroy_geofence(account: &signer, geofence: Object<GeoFence>) acquires GeoFence {
        let account_address = signer::address_of(account);
        assert!(object::owner(geofence) == account_address, E_NOT_AUTHORIZED);   
         let object_address = object::object_address(&geofence);
 
    // Retrieve the delete ref, it is consumed so it must be extracted
        // from the resource
        let GeoFence {
            name,
            start_date,
            end_date,
            longitude_coordinate,
            latitude_coordinate,
            radius_miles,
            mutator_ref,
            uri,
            delete_ref
        } = move_from<GeoFence>(object_address);
 
        // Delete the object forever!
        object::delete(delete_ref);
    }
}
 
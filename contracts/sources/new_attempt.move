module my_management_addr::on_chain_geo_v1 {
    use std::string::{Self, String};
    use std::math128::{pow, sqrt};
    use aptos_framework::object::{Self, Object};
    use std::option::{Self};
    use aptos_token_objects::collection;
    use aptos_token_objects::token;
    use aptos_framework::timestamp; // Import the Timestamp module
    use std::signer;

    #[test_only]
    use aptos_std::debug::print;

    struct GeoCoordinate has store, copy, drop {
        latitude: u128,
        latitude_is_negative: bool,
        longitude: u128,
        longitude_is_negative: bool 
    }

    #[resource_group_member(group = aptos_framework::object::ObjectGroup)]
    struct GeoFence has key {
        name: String,
        start_date: u64,
        end_date: u64,
        geo_coordinate: GeoCoordinate,
        radius_miles: u128,               // Fixed-point with 8 decimals
        mutator_ref: collection::MutatorRef,
        uri: String,
    }
    const E_NOT_AUTHORIZED: u64 = 1;
    const EMPTY_STRING: vector<u8> = b"";
    const DECIMALS: u128 = 100000000; // 8 decimal places
    const MIDDLE_POINT: u128 = 18000000000; // Middle point for longitude/latitude with 8 decimal places

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
        let geo_coordinate = GeoCoordinate { 
            longitude: longitude_value, 
            longitude_is_negative, 
            latitude: latitude_value, 
            latitude_is_negative 
        };

        let collection_constructor_ref = collection::create_unlimited_collection(
            account,
            string::utf8(EMPTY_STRING),
            name,
            option::none(),
            uri,
        );
        let object_signer = object::generate_signer(&collection_constructor_ref);
        let mutator_ref = collection::generate_mutator_ref(&collection_constructor_ref);
        let new_geofence = GeoFence {
            name,
            start_date,
            end_date,
            geo_coordinate,
            radius_miles,
            mutator_ref,
            uri,
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
        let geo_coordinate = GeoCoordinate { 
            longitude: longitude_value, 
            longitude_is_negative, 
            latitude: latitude_value, 
            latitude_is_negative 
        };

        let geofence_obj = borrow_global<GeoFence>(object::object_address(&geofence));
        let within_geo = Self::haversine_distance(
            geofence_obj.geo_coordinate,
            geo_coordinate
        ) <= geofence_obj.radius_miles;

        let current_time = timestamp::now_seconds();

        if (within_geo && current_time >= geofence_obj.start_date && current_time <= geofence_obj.end_date) {
            // Mint a token to the signer
            token::create_named_token(admin, geofence_obj.name, string::utf8(EMPTY_STRING), ticket_id, option::none(), geofence_obj.uri);
        }
    }

const   MIDDLE_POINT_LON: u128 = 18000000000;
const   MIDDLE_POINT_LAT: u128 = 9000000000;
// Haversine formula to calculate the distance between two points on the Earth's surface
fun haversine_distance(coord1: GeoCoordinate, coord2: GeoCoordinate): u128 {
    let radius_of_earth: u128 = 6371000; // Radius of the Earth in meters

    // Convert coordinates to u128
    let lat1 = Self::coordinate_to_u128_latitude(coord1.latitude, coord1.latitude_is_negative);
    let lon1 = Self::coordinate_to_u128_longitude(coord1.longitude, coord1.longitude_is_negative);

    let lat2 = Self::coordinate_to_u128_latitude(coord2.latitude, coord2.latitude_is_negative);
    let lon2 = Self::coordinate_to_u128_longitude(coord2.longitude, coord2.longitude_is_negative);

    // Use coordinate_diff to avoid overflow
    let dlat = Self::to_radians(Self::coordinate_diff(lat2, lat1));
    aptos_std::debug::print(&dlat);
    let dlon = Self::to_radians(Self::coordinate_diff(lon2, lon1));
    aptos_std::debug::print(&dlon);
    
    let a = pow(sin(dlat / 2), 2) +
            cos(Self::to_radians(lat1)) * cos(Self::to_radians(lat2)) * pow(sin(dlon / 2), 2);
    
    let a = std::math128::min(a, DECIMALS * DECIMALS); // Ensure 'a' does not exceed DECIMALS * DECIMALS
    let c = 2 * atan2(sqrt(a), sqrt(DECIMALS * DECIMALS - a));
    
    return radius_of_earth * c // Distance in meters
}

// Convert degrees to radians
fun to_radians(degrees: u128): u128 {
    let pi: u128 = 314159265; // Approximation of pi (fixed-point with 8 decimals)
    return degrees * pi / 180000000 // Convert degrees to radians
}

// Sine function approximation using Taylor series
 fun sin(x: u128): u128 {
    let x_fixed = x % (DECIMALS * 2); // Normalize x to [0, 2]
    let x2 = (x_fixed * x_fixed) / DECIMALS; // x^2
    let x3 = (x_fixed * x2) / DECIMALS; // x^3
    let x5 = (x_fixed * x3 * x2) / DECIMALS; // x^5
    let x7 = (x_fixed * x5 * x2) / DECIMALS; // x^7

    // Taylor series expansion: sin(x) about= x - x^3/3! + x^5/5! - x^7/7!
    let result = x_fixed
        - x3 / 6 // 3! = 6
        + x5 / 120 // 5! = 120
        - x7 / 5040; // 7! = 5040

    // Clamp result to avoid negative outputs
    return if result > DECIMALS { DECIMALS } else { result }
}
// Cosine function approximation using Taylor series
fun cos(x: u128): u128 {
    let x_fixed = x % (DECIMALS * 2); // Limit x to the range of 0 to 2pi
    let x2 = (x_fixed * x_fixed) / DECIMALS; // x^2
    let x4 = (x2 * x2) / DECIMALS; // x^4
    let x6 = (x4 * x2) / DECIMALS; // x^6
    
    return DECIMALS - x2 / 2 + x4 / 24 - x6 / 720 // Taylor series expansion
}

// Arctangent function approximation using Taylor series
fun atan2(y: u128, x: u128): u128 {
    if (x == 0 && y == 0) {
        return 0 // Handle the undefined case
    } else if (x > 0) {
        return (y * DECIMALS) / x // First quadrant
    } else if (x < 0 && y >= 0) {
        return DECIMALS - (y * DECIMALS) / x // Second quadrant
    } else if (x < 0 && y < 0) {
        return DECIMALS + (y * DECIMALS) / x // Third quadrant
    } else {
        return DECIMALS * 2 - (y * DECIMALS) / x // Fourth quadrant
    }
}

// Helper function to calculate the difference between two coordinates
fun coordinate_diff(coord1: u128, coord2: u128): u128 {
    return if (coord1 > coord2) {
        coord1 - coord2
    } else {
        coord2 - coord1
    }
}

// Helper function to convert a Coordinate to u128
fun coordinate_to_u128_latitude(direction: u128, is_negative: bool): u128 {
    return if (is_negative) {
        MIDDLE_POINT_LAT + direction
    } else {
        direction
    }
}

fun coordinate_to_u128_longitude(direction: u128, is_negative: bool): u128 {
    return if (is_negative) {
        MIDDLE_POINT_LON + direction
    } else {
        direction
    }
}

    #[test]
    fun test_haversine_distance() {
        //MCCARTHY PARK
        let coord1 = GeoCoordinate {
            latitude: 4071991100, // 40.719911 with 8 decimal places
            latitude_is_negative: false,
            longitude: 7395141400, // - 73.951414 with 8 decimal places
            longitude_is_negative: true,
        };

        // REAlly FAR Away
        let coord2 = GeoCoordinate {
            latitude: 6300163100, // 63.001631 with 8 decimal places
            latitude_is_negative: false,
            longitude: 15786176000, // - 157.861760 with 8 decimal places
            longitude_is_negative: true,
        };

        let distance = haversine_distance(coord1, coord2);

        // Print the distance for verification
        aptos_std::debug::print(&distance);
    }
}
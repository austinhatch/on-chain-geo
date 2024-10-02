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

    struct SignedInteger has store, copy, drop {
        value: u128,
        is_negative: bool
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

const   LON_OFFSET: u128 = 18000000000;
const   LAT_OFFSET: u128 = 9000000000;
// Haversine formula to calculate the distance between two points on the Earth's surface
fun haversine_distance(coord1: GeoCoordinate, coord2: GeoCoordinate): u128 {
    let radius_of_earth: u128 = 6371000; // Radius of the Earth in meters

    // Convert coordinates to u128
    let lat1 = Self::coordinate_to_signed_integer(coord1.latitude, coord1.latitude_is_negative);
    let lon1 = Self::coordinate_to_signed_integer(coord1.longitude, coord1.longitude_is_negative);

    let lat2 = Self::coordinate_to_signed_integer(coord2.latitude, coord2.latitude_is_negative);
    let lon2 = Self::coordinate_to_signed_integer(coord2.longitude, coord2.longitude_is_negative);

    let lat1_rad = to_radians(lat1);
    let lon1_rad = to_radians(lon1);
    let lat2_rad = to_radians(lat2);
    let lon2_rad = to_radians(lon2);

    aptos_std::debug::print(&lat1_rad);
    aptos_std::debug::print(&lon1_rad);
    aptos_std::debug::print(&lat2_rad);
    aptos_std::debug::print(&lon2_rad);

    // Differences in coordinates
    let dlat = Self::coordinate_diff(lat1, lat2);
    let dlon = Self::coordinate_diff(lon1, lon2);
    
    aptos_std::debug::print(&dlat);
    aptos_std::debug::print(&dlon);
    
    let a = pow(sin(dlat / 2), 2) +
            cos(lat1_rad) * cos(lat2_rad) * pow(sin(dlon / 2), 2);
    
    let a = std::math128::min(a, DECIMALS * DECIMALS); // Ensure 'a' does not exceed DECIMALS * DECIMALS
    let c = 2 * atan2(sqrt(a), sqrt(DECIMALS * DECIMALS - a));
    
    return radius_of_earth * c // Distance in meters
}

// Convert degrees to radians
fun to_radians(degrees: SignedInteger): SignedInteger {
    let pi: u128 = 314159265;// Approximation of pi (fixed-point with 8 decimals)
    let radians: u128 = degrees.value * pi / 180000000 // Convert degrees to radians using 18 decimals
    return SignedInteger { value: radians, is_negative: degrees.is_negative }
}

// Sine function approximation using Taylor series
 fun sin(x: SignedInteger): SignedInteger {
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
    return if (result > DECIMALS) { DECIMALS } else { result }
}
// Cosine function approximation using Taylor series
fun cos(x: SignedInteger): SignedInteger {
    let x_fixed = x % (DECIMALS * 2); // Limit x to the range of 0 to 2pi
    let x2 = (x_fixed * x_fixed) / DECIMALS; // x^2
    let x4 = (x2 * x2) / DECIMALS; // x^4
    let x6 = (x4 * x2) / DECIMALS; // x^6
    
    return DECIMALS - x2 / 2 + x4 / 24 - x6 / 720 // Taylor series expansion
}

// Arctangent function approximation using Taylor series
fun atan2(y: SignedInteger, x: SignedInteger): SignedInteger {
    let pi_half: u128 = 1570796326794896619; // pi / 2
    let pi: u128 = 3141592653589793238;
    
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
fun coordinate_diff(coord1: SignedInteger, coord2: SignedInteger): SignedInteger {
    // If both coordinates are negative
    if(coord1.is_negative && coord2.is_negative) {
        if(coord1.value > coord2.value){
            return SignedInteger { value: coord1.value + coord2.value, is_negative: true }
        } else {
            return SignedInteger { value: coord2.value - coord1.value, is_negative: false }
        }
    }

    //If both coordinates are positive
    if(!coord1.is_negative && !coord2.is_negative) {
        if(coord1.value > coord2.value){
            return SignedInteger { value: coord1.value - coord2.value, is_negative: false }
        } else {
            return SignedInteger { value: coord1.value - coord2.value, is_negative: true }
        }
    }

    //If coord1 is negative and coord2 is positive
    if(coord1.is_negative && !coord2.is_negative) {
        return SignedInteger { value: coord1.value + coord2.value, is_negative: true }
    }

    //If coord1 is positive and coord2 is negative
    if(!coord1.is_negative && coord2.is_negative) {
        return SignedInteger { value: coord2.value - coord1.value, is_negative: true }
    }
}

// Helper function to convert a Coordinate to u128
// fun coordinate_to_u128_latitude(direction: u128, is_negative: bool): SignedInteger {
//     return SignedInteger { value: direction, is_negative }
// }

// fun coordinate_to_u128_longitude(direction: u128, is_negative: bool): SignedInteger {
//     return SignedInteger { value: direction, is_negative }
// }

fun coordinate_to_signed_integer(direction: u128, is_negative: bool): SignedInteger {
    return SignedInteger { value: direction, is_negative }
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
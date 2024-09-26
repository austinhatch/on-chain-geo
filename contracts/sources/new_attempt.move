module my_management_addr::on_chain_geo {
    use std::string::{Self, String};
    use std::math128::{pow, sqrt};
    use std::signer;
    use std::error;
    use aptos_framework::object::{Self, Object};
    use std::option::{Self, Option};
    use aptos_token_objects::collection;
    use aptos_token_objects::token;

    #[resource_group_member(group = aptos_framework::object::ObjectGroup)]
    struct GeoFence has key {
        name: String,
        start_date: u64,
        end_date: u64,
        longitude_coordinate: u128,
        latitude_coordinate: u128,
        radius_miles: u128,
        radius_decimals: u128,
        mutator_ref: collection::MutatorRef,
        uri: String,
    }

    const EMPTY_STRING: vector<u8> = b"";

    public entry fun create_geofence(
        account: &signer, 
        name: String, 
        start_date: u64, 
        end_date: u64, 
        longitude_coordinate: u128, 
        latitude_coordinate: u128, 
        radius_miles: u128, 
        radius_decimals: u128,
        uri: String
    )  {
        let collection_constructor_ref = collection::create_unlimited_collection(
            account,
            string::utf8(EMPTY_STRING),
            name,
            option::none(),
            uri,
        );
        let object_signer = object::generate_signer(&collection_constructor_ref);
        let transfer_ref = object::generate_transfer_ref(&collection_constructor_ref);
        let mutator_ref = collection::generate_mutator_ref(&collection_constructor_ref);
        let extend_ref = object::generate_extend_ref(&collection_constructor_ref);
        
        object::disable_ungated_transfer(&transfer_ref);

        let new_geofence = GeoFence {
            name,
            start_date,
            end_date,
            longitude_coordinate,
            latitude_coordinate,
            radius_miles,
            radius_decimals,
            mutator_ref,
            uri,
        };

        move_to(&object_signer, new_geofence);
    }

    
    public entry fun is_within_geo(admin: &signer, geofence: Object<GeoFence>, longitude: u128, latitude: u128, ticket_id: String) acquires GeoFence {
        let geofence_obj = borrow_global<GeoFence>(object::object_address(&geofence));
        let radius = (geofence_obj.radius_miles as u128) + (geofence_obj.radius_decimals as u128) / pow(10, 8);
        let within_geo = Self::haversine_distance(
            geofence_obj.latitude_coordinate,
            geofence_obj.longitude_coordinate,
            latitude,
            longitude
        ) <= radius;

        if (within_geo) {
            // Mint a token to the signer
            let token_constructor_ref = token::create_named_token(admin, geofence_obj.name, string::utf8(EMPTY_STRING), ticket_id, option::none(), geofence_obj.uri);
        }

    }



    // Haversine formula to calculate the distance between two points on the Earth's surface
    fun haversine_distance(lat1: u128, lon1: u128, lat2: u128, lon2: u128): u128 {
        let radius_of_earth: u128 = 6371000; // Radius of the Earth in meters
        let dlat = Self::to_radians(lat2 - lat1);
        let dlon = Self::to_radians(lon2 - lon1);
        let a = pow(sin(dlat / 2), 2) + cos(Self::to_radians(lat1)) * cos(Self::to_radians(lat2)) * pow(sin(dlon / 2), 2);
        let c = 2 * atan2(sqrt(a), sqrt(1 - a));
        return radius_of_earth * c
    }

    // Convert degrees to radians
    fun to_radians(degrees: u128): u128 {
        let pi: u128 = 3141592653589793238; // Approximation of pi
        return degrees * pi / 1800000000000000000
    }

        // Sine function approximation using Taylor series
    fun sin(x: u128): u128 {
        let x3 = pow(x, 3);
        let x5 = pow(x, 5);
        let x7 = pow(x, 7);
        return x - x3 / 6 + x5 / 120 - x7 / 5040
    }

    // Cosine function approximation using Taylor series
    fun cos(x: u128): u128 {
        let x2 = pow(x, 2);
        let x4 = pow(x, 4);
        let x6 = pow(x, 6);
        return 1 - x2 / 2 + x4 / 24 - x6 / 720
    }

    // Arctangent function approximation using Taylor series
    fun atan2(y: u128, x: u128): u128 {
        // Simple approximation for atan2
        if (x > y) {
            return y / x
        } else {
            return x / y
        }
    }


}
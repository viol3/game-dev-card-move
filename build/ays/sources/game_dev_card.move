module ays::game_dev_card
{
    use std::string::{Self, String};
    use std::vector;
    use sui::object::{Self, ID, UID}; 
    use sui::transfer;
    use sui::tx_context::{Self, TxContext};
    use sui::dynamic_field as df;
    use sui::event;

    public struct DonkeySaddle has key 
    {
        id: UID
    }

    // We added the 'key' ability to make the GameItem an independent object.
    // We removed the 'drop' ability because objects with a 'key' cannot be dropped; they must be 'deleted'.
    public struct GameItem has key, store
    {
        id: UID,
        game_name: String,
        game_link: String,
        description: String,
        image_url: String,
        platform: String
    }

    public struct GameDevCardProfile has key, store 
    {
        id: UID,
        name: String,
        // We changed the type of the 'games' vector from vector<GameItem> to vector<ID>.
        // It will now store only the IDs of the GameItem objects, not the objects themselves.
        games: vector<ID>
    }

    public entry fun init_saddle(ctx: &mut TxContext)
    {
        let saddle = DonkeySaddle { id: object::new(ctx) };
        transfer::share_object(saddle);
    }

    #[allow(lint(self_transfer))]
    public entry fun create_game_dev_profile(name: String, saddle: &mut DonkeySaddle, ctx: &mut TxContext) 
    {
        let name_len = std::string::length(&name);
        assert!(name_len >= 3, 1);   
        assert!(name_len <= 40, 2);  

        let gamedevcard = GameDevCardProfile {
            id: object::new(ctx),
            name: name,
            games: vector[],
            
        };

        assert!(df::exists_(&saddle.id, name) == false, 99);


        let profile_id = object::id(&gamedevcard);
        df::add(&mut saddle.id, name, profile_id);
        transfer::transfer(gamedevcard, ctx.sender());
    }

    #[allow(lint(self_transfer))]
    public entry fun add_game(
        mut profile: GameDevCardProfile, 
        game_name: String,
        game_link: String,
        description: String,
        image_url: String,
        platform: String,
        ctx: &mut TxContext
    ) 
    {
        let game_name_len = std::string::length(&game_name);
        assert!(game_name_len >= 3, 1); 
        assert!(game_name_len <= 250, 2);

        let game_link_len = std::string::length(&game_link);
        assert!(game_link_len >= 3, 3); 
        assert!(game_link_len <= 1000, 4);

        let description_len = std::string::length(&description);
        assert!(description_len >= 3, 5); 
        assert!(description_len <= 1000, 6);

        let image_url_len = std::string::length(&image_url);
        assert!(image_url_len >= 10, 7); 
        assert!(image_url_len <= 1000, 8);

        let platform_len = std::string::length(&platform);
        assert!(platform_len >= 1, 9); 
        assert!(platform_len <= 250, 10);

        // We create the new GameItem object as a struct.
        let new_game = GameItem 
        {
            id: object::new(ctx),
            game_name,
            game_link,
            description,
            image_url,
            platform,
        };

        // We get the ID of the object we created.
        // This ID is the global address the object will receive when we transfer it.
        let new_game_id = object::uid_to_inner(&new_game.id);

        // We are adding only the 'ID' of the struct to the 'games' vector of the profile, not the struct itself.
        vector::push_back(&mut profile.games, new_game_id);

        // We transfer the modified profile back to the user.
        transfer::transfer(profile, ctx.sender());

        // We also transfer the newly created GameItem object to the user.
        // This operation converts the 'new_game' structure into an object in global storage.
        transfer::transfer(new_game, ctx.sender());
    }

    #[allow(lint(self_transfer))]
    public entry fun update_profile_name(
        mut profile: GameDevCardProfile,
        new_name: String,
        ctx: &mut TxContext
    ) {
        let name_len = std::string::length(&new_name);
        assert!(name_len >= 3, 100); 
        assert!(name_len <= 40, 101); 

        profile.name = new_name;
        
        transfer::transfer(profile, ctx.sender());
    }

    #[allow(lint(self_transfer))]
    public entry fun update_game(
        mut profile: GameDevCardProfile, 
        mut game_to_update: GameItem, 
        game_name: String,
        game_link: String,
        description: String,
        image_url: String,
        platform: String,
        ctx: &mut TxContext
    ) 
    {
        let game_name_len = std::string::length(&game_name);
        assert!(game_name_len >= 3, 1); 
        assert!(game_name_len <= 250, 2);

        let game_link_len = std::string::length(&game_link);
        assert!(game_link_len >= 3, 3); 
        assert!(game_link_len <= 1000, 4);

        let description_len = std::string::length(&description);
        assert!(description_len >= 3, 5); 
        assert!(description_len <= 1000, 6);

        let image_url_len = std::string::length(&image_url);
        assert!(image_url_len >= 10, 7); 
        assert!(image_url_len <= 1000, 8);

        let platform_len = std::string::length(&platform);
        assert!(platform_len >= 1, 9); 
        assert!(platform_len <= 250, 10);
        
        let id_to_update = object::id(&game_to_update);
        
        assert!(
            vector::contains(&profile.games, &id_to_update), 
            202
        );
                
        game_to_update.game_name = game_name;
        game_to_update.game_link = game_link;
        game_to_update.description = description;
        game_to_update.image_url = image_url;
        game_to_update.platform = platform;
        transfer::transfer(profile, ctx.sender());
        transfer::transfer(game_to_update, ctx.sender());
    }

    #[allow(lint(self_transfer))]
    public entry fun remove_game(
        mut profile: GameDevCardProfile,
        game: GameItem, // We take the 'GameItem' object itself as a parameter
        ctx: &mut TxContext
    ) {
        // We get the ID of the 'game' object to be removed.
        let id_to_remove = object::id(&game);

        // We must manually delete the 'game' object because it has the 'key' capability. // We open the struct and call object::delete with the 'id' (UID) in it.
        let GameItem {
            id, 
            game_name,
            game_link,
            description,
            image_url,
            platform } = game;
        object::delete(id);
        
        // We find this ID in the profile's 'games' (vector<ID>) list and delete it.
        let len = vector::length(&profile.games);
        let mut i = 0;
        while (i < len) 
        {
            // Get the ID (address) in the vector
            let game_id_in_list = vector::borrow(&profile.games, i);
            
            // Compare with the ID of the object to be deleted
            if (*game_id_in_list == id_to_remove) {
                // If a match is found, remove it from the vector with 'swap_remove'
                vector::swap_remove(&mut profile.games, i);
                break; 
            };
            i = i + 1;
        };

        transfer::transfer(profile, ctx.sender());
    }
}
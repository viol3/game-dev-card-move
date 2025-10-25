module ays::game_dev_card
{
    use std::string::String;

    public struct GameItem has store, drop
    {
        id: UID,
        game_name: String,
        
    }
    public struct GameDevCardProfile has key, store 
    {
        id: UID,
        name: String,
        games: vector<GameItem>
        //description: String,
        //game_url: String,
    }


    #[allow(lint(self_transfer))]
public entry fun add_game_to_profile(
    mut profile: GameDevCardProfile, 
    game_name: String, 
    ctx: &mut TxContext
) 
{
   
    let game_len = std::string::length(&game_name);
    assert!(game_len >= 3, 1); 
    assert!(game_len <= 50, 2);


    let new_game = GameItem {
        id: object::new(ctx),
        game_name: game_name,
    };

   
    vector::push_back(&mut profile.games, new_game);

    
    transfer::transfer(profile, ctx.sender());
}

public entry fun remove_game_by_id(
    mut profile: GameDevCardProfile,
    game: GameItem,
    ctx: &mut TxContext
) {
    let GameItem {id, game_name } = game;
    let len = vector::length(&profile.games);
    let mut i = 0;
    while (i < len) 
    {
        let gameRef = vector::borrow(&profile.games, i);
        if (object::id(&gameRef.id) == id) {
            
            vector::swap_remove(&mut profile.games, i);
           
            break;
        };
        i = i + 1;
    };
   
    transfer::transfer(profile, ctx.sender());
}


}


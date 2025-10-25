module ays::game_dev_card
{
    // Gerekli importları ekliyoruz
    use std::string::{Self, String};
    use std::vector;
    use sui::object::{Self, ID, UID}; // 'ID' tipini import ediyoruz
    use sui::transfer;
    use sui::tx_context::{Self, TxContext};

    // 1. GameItem'ı bağımsız bir obje yapmak için 'key' yeteneği ekledik.
    // 'drop' yeteneğini kaldırdık çünkü 'key' olan objeler drop edilemez, 'delete' edilmelidir.
    public struct GameItem has key, store
    {
        id: UID,
        game_name: String,
    }

    public struct GameDevCardProfile has key, store 
    {
        id: UID,
        name: String,
        // 2. 'games' vektörünün tipini vector<GameItem>'dan vector<ID>'ye değiştirdik.
        // Artık GameItem objelerinin kendilerini değil, sadece ID'lerini saklayacak.
        games: vector<ID>
    }

    #[allow(lint(self_transfer))]
    public entry fun create_game_dev_profile(name: String, ctx: &mut TxContext) 
    {
        let name_len = std::string::length(&name);
        assert!(name_len >= 3, 1);   
        assert!(name_len <= 40, 2);  

        let simple_nft = GameDevCardProfile {
            id: object::new(ctx),
            name: name,
            games: vector[],
            
        };
        transfer::transfer(simple_nft, ctx.sender())
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

        // 3. Yeni GameItem objesini bir struct olarak oluşturuyoruz.
        let new_game = GameItem {
            id: object::new(ctx),
            game_name: game_name,
        };

        // 4. Oluşturduğumuz objenin ID'sini alıyoruz.
        // Bu ID, objeyi transfer ettiğimizde alacağı global adrestir.
        let new_game_id = object::uid_to_inner(&new_game.id);

        // 5. Profilin 'games' vektörüne struct'ın kendisini değil, sadece 'ID'sini ekliyoruz.
        vector::push_back(&mut profile.games, new_game_id);

        // 6. Değiştirilmiş profili kullanıcıya geri transfer ediyoruz.
        transfer::transfer(profile, ctx.sender());

        // 7. (İsteğiniz) Yeni oluşturulan GameItem objesini de kullanıcıya transfer ediyoruz.
        // Bu işlem, 'new_game' struct'ını global depolamada bir objeye dönüştürür.
        transfer::transfer(new_game, ctx.sender());
    }


    #[allow(lint(self_transfer))]
    public entry fun remove_game_by_id(
        mut profile: GameDevCardProfile,
        game: GameItem, // Parametre olarak 'GameItem' objesinin kendisini alıyoruz
        ctx: &mut TxContext
    ) {
        // 8. Kaldırılacak 'game' objesinin ID'sini alıyoruz.
        let id_to_remove = object::id(&game);

        // 9. 'game' objesini 'key' yeteneğine sahip olduğu için manuel olarak silmeliyiz.
        // Struct'ı açıp içindeki 'id' (UID) ile object::delete çağırıyoruz.
        let GameItem {id, game_name } = game;
        object::delete(id); // Obje depolamadan silindi.
        
        // 10. Profilin 'games' (vector<ID>) listesinde bu ID'yi bulup siliyoruz.
        let len = vector::length(&profile.games);
        let mut i = 0;
        while (i < len) 
        {
            // Vektördeki ID'yi (adresi) al
            let game_id_in_list = vector::borrow(&profile.games, i);
            
            // Silinecek objenin ID'si ile karşılaştır
            if (*game_id_in_list == id_to_remove) {
                // Eşleşme bulunursa, vektörden 'swap_remove' ile çıkar
                vector::swap_remove(&mut profile.games, i);
                break; // Döngüden çık
            };
            i = i + 1;
        };
        
        // 11. Güncellenmiş profili kullanıcıya geri transfer et
        transfer::transfer(profile, ctx.sender());
    }
}
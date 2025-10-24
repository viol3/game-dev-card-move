module ays::game_dev_card
{
    use std::string::String;
    
    public struct GameDevCardItem has key, store 
    {
        id: UID,
        name: String,
        description: String,
        image_url: String,
    }

    public struct GAME_DEV_CARD_ITEM has drop {}

    fun init(otw: GAME_DEV_CARD_ITEM, ctx: &mut TxContext) 
    {
        let keys = vector[
            b"name".to_string(),
            b"description".to_string(),
            b"image_url".to_string(),
        ];

        let values = vector[
            b"{name}".to_string(),
            b"{description}".to_string(),
            b"{image_url}".to_string(),
        ];

        let publisher = sui::package::claim(otw, ctx);

        let mut display = sui::display::new_with_fields<GameDevCardItem>(
            &publisher,
            keys,
            values,
            ctx,
        );

        display.update_version();

        transfer::public_transfer(publisher, ctx.sender());
        transfer::public_transfer(display, ctx.sender());
    }

    #[allow(lint(self_transfer))]
    public entry fun create_simple_nft(name: String, ctx: &mut TxContext) 
    {
        let simple_nft = GameDevCardItem {
            id: object::new(ctx),
            name: name,
            description: b"A Game Dev Card Item".to_string(),
            image_url: b"https://i.imgur.com/5LOzwSR.png".to_string(),
        };

        transfer::transfer(simple_nft, ctx.sender());
    }
}

pragma ton-solidity >=0.35.0;
pragma AbiHeader expire;
pragma AbiHeader time;
pragma AbiHeader pubkey;


import "ListDebot.sol";


contract ShopDebot is ListDebot{

    function _menu() internal override {
        string sep = '----------------------------------------';
        Menu.select(
            format(
                "You have {}/{} (unpaid/paid) purhases. Total price of purchases {}",
                    m_stat.incompleteCount,
                    m_stat.completeCount,
                    m_stat.totalPrice
            ),
            sep,
            [
                MenuItem("Buy purchase","",tvm.functionId(buy)),
                MenuItem("Show shopping list","",tvm.functionId(showShopping)),
                MenuItem("Delete purchase","",tvm.functionId(deleteShopping))
            ]
        );
    }
    function buy(uint32 index) public {
        index = index;
        if (m_stat.completeCount + m_stat.incompleteCount > 0) {
            Terminal.input(tvm.functionId(buy_), "Enter purchase number:", false);
        } else {
            Terminal.print(0, "Sorry, you have no purchases to update");
            _menu();
        }
    }

    function buy_(string value) public {
        (uint256 num,) = stoi(value);
        m_taskId = uint32(num);
        ConfirmInput.get(tvm.functionId(buy__),"Is this purchase completed?");
    }

    function buy__(string value) public view {
        (uint256 num,) = stoi(value);
        m_price = uint32(num);
        optional(uint256) pubkey = 0;
        ITodo(m_address).buy{
                abiVer: 2,
                extMsg: true,
                sign: true,
                pubkey: pubkey,
                time: uint64(now),
                expire: 0,
                callbackId: tvm.functionId(onSuccess),
                onErrorId: tvm.functionId(onError)
            }(m_taskId, m_price);
    }



    function showShopping(uint32 index) public view {
        index = index;
        optional(uint256) none;
        ITodo(m_address).getShopping{
            abiVer: 2,
            extMsg: true,
            sign: false,
            pubkey: none,
            time: uint64(now),
            expire: 0,
            callbackId: tvm.functionId(showPurchases_),
            onErrorId: 0
        }();
    }

    function showPurchases_( Shopping[] purchases ) public {
        uint32 i;
        if (purchases.length > 0 ) {
            Terminal.print(0, "Your Shopping list:");
            for (i = 0; i < purchases.length; i++) {
                Shopping purchase = purchases[i];
                string bought;
                if (purchase.isBought) {
                    bought = '✓';
                } else {
                    bought = ' ';
                }
                Terminal.print(0, format("{} {}  \"{}\"({}) add at {}", purchase.id, bought, purchase.name, purchase.quantity, purchase.createdAt));
            }
        } else {
            Terminal.print(0, "Your Shopping list is empty");
        }
        onSuccess();
    }
    function deleteShopping(uint32 index)  public {
        index = index;
        if (m_stat.completeCount + m_stat.incompleteCount > 0) {
            Terminal.input(tvm.functionId(deleteShopping_), "Enter purchase number:", false);
        } else {
            Terminal.print(0, "Sorry, you have no purchases to delete");
            _menu();
        }
    }

    function deleteShopping_(string value) public view {
        (uint256 num,) = stoi(value);
        optional(uint256) pubkey = 0;
        ITodo(m_address).deleteShopping{ // вызываем метод deleteShopping из интерефейса ITodo
                abiVer: 2,
                extMsg: true,
                sign: true,
                pubkey: pubkey,
                time: uint64(now),
                expire: 0,
                callbackId: tvm.functionId(onSuccess),
                onErrorId: tvm.functionId(onError)
            }(uint32(num));
    }
}
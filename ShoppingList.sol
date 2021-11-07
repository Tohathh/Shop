pragma ton-solidity >= 0.35.0;
pragma AbiHeader expire;
pragma AbiHeader pubkey;

import "structAndInterface.sol";

contract ShoppingList {
    /*
     * ERROR CODES
     * 100 - Unauthorized
     * 102 - task not found
     */
        //модификатор с проверкой прав доступа
    modifier onlyOwner() {
        require(msg.pubkey() == m_ownerPubkey, 101);
        _;
    }

    uint32 m_count;

        //сопоставление
    mapping(uint32 => Shopping) m_shopping;

    uint256 m_ownerPubkey;

    constructor(uint256 pubkey) public {
        require(pubkey != 0, 120);
        tvm.accept();
        m_ownerPubkey = pubkey;
    }

        //функция добавления покупки в список
    function createShopping(string name, uint32 quantity, uint price) public onlyOwner {
        tvm.accept();
        m_count++;
        m_shopping[m_count] = Shopping(m_count, name, quantity, now, false, price);
    }

        //функция купить
    function buy(uint32 id, uint price, bool done) public onlyOwner {
        optional(Shopping) shopping = m_shopping.fetch(id);
        require(shopping.hasValue(), 102);
        tvm.accept();
        Shopping thisShopping = shopping.get();
        thisShopping.isBought = done;
        m_shopping[id] = thisShopping;
    }
        //удаление покупки из списка
    function deleteShopping(uint32 id) public onlyOwner {
        require(m_shopping.exists(id), 102);
        tvm.accept();
        delete m_shopping[id];
    }
        
    
        //функция получения статистики по покупкам
    function getStat() public view returns (ShoppingSammari stat) {
        uint32 completeCount;
        uint32 incompleteCount;
        uint totalPrice; 
            //проходим по всем задачам
        for((, Shopping task) : m_shopping) {
            if  (task.isBought) {
                completeCount ++;
            } else {
                incompleteCount ++;
            }
        }
        stat = ShoppingSammari(completeCount, incompleteCount, totalPrice);
    }
}


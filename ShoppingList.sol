pragma ton-solidity >= 0.35.0;
pragma AbiHeader expire;
pragma AbiHeader pubkey;

import "structAndInterface.sol";

contract ShoppingList {
    
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
    function createShopping(string name, uint32 quantity) public onlyOwner {
        tvm.accept();
        m_count++;
        m_shopping[m_count] = Shopping(m_count, name, quantity, now, false, 0);
    }

        //функция купить
    function buy(uint32 id, uint32 price) public onlyOwner {
        optional(Shopping) shopping = m_shopping.fetch(id);
        require(shopping.hasValue(), 102);
        tvm.accept();
        Shopping thisShopping = shopping.get();
        thisShopping.price = thisShopping.quantity * price;
        thisShopping.isBought = true;
        m_shopping[id] = thisShopping;
    }
        //удаление покупки из списка
    function deleteShopping(uint32 id) public onlyOwner {
        require(m_shopping.exists(id), 102);
        tvm.accept();
        delete m_shopping[id];
    }
        
        function getShopping() public view returns (Shopping[] purchases) {
        string name;
        uint32 quantity;
        uint64 createdAt;
        bool isBought;
        uint32 price;

        for((uint32 id, Shopping shopping) : m_shopping) {// циклом проходимся по всем задачам
            name = shopping.name;
            quantity = shopping.quantity;
            createdAt = shopping.createdAt;
            isBought = shopping.isBought;
            price = shopping.price;
            purchases.push(Shopping(id, name, quantity, createdAt, isBought, price));// формируем структуру Shopping и добавление в массив 
       }
    }

        //функция получения статистики по покупкам
    function getStat() public view returns (ShoppingSammari stat) {
        uint32 completeCount; //
        uint32 incompleteCount;
        uint32 totalPrice; 
            //проходим по всем задачам
        for((, Shopping task) : m_shopping) {
            if  (task.isBought) {
                completeCount = completeCount + task.quantity;
                totalPrice = totalPrice + task.price;
            } else {
                incompleteCount = incompleteCount + task.quantity;
            }
        }
        stat = ShoppingSammari(completeCount, incompleteCount, totalPrice);
    }
}


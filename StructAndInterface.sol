pragma ton-solidity >=0.35.0;
pragma AbiHeader expire;
pragma AbiHeader time;
pragma AbiHeader pubkey;

struct Shopping { // структура Покупка
        uint32 id; //  идентификатор
        string name; // название покупки
        uint32 quantity; // количество
        uint64 createdAt; // когда заведена покупка, время или дата
        bool isBought; // куплено
        uint price; //цена, за которую купили  [за все единиицы сразу] 
}

struct ShoppingSammari { //структура Саммари покупок
        uint32 completeCount; // оплаченные покупки (предметы, количество)
        uint32 incompleteCount; // неоплаченные покупки (предметы, количество)
        uint totalPrice; // сумма покупок
}

interface IMsig {
   function sendTransaction(address dest, uint128 value, bool bounce, uint8 flags, TvmCell payload  ) external;
}


abstract contract HasConstructorWithPubKey {
    //используется конструктор, как в shoppingList.sol, передача публичного ключа и сохранение в m_ownerPubkey файла shoppingList.sol
   constructor(uint256 pubkey) public {}
}

// интерфейс ITodo, в котором представлены методы, д.б. реализованы  в классах-наследниках
interface ITodo {
   function createShopping(string name, uint32 quantity, uint price) external;
   function buy(uint32 id, uint price, bool done) external;
   function deleteShopping(uint32 id) external;
   function getStat() external returns (ShoppingSammari);
}
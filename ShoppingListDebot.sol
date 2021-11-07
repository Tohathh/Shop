pragma ton-solidity >=0.35.0;
pragma AbiHeader expire;
pragma AbiHeader time;
pragma AbiHeader pubkey;


import "ListDebot.sol";


contract ShoppingListDebot is ListDebot{


    function _createShopping(uint32 index) public {
        createShopping(index); // добавление покупки
    }

    function statistic()  public {
       _menu(); //получение статистики с помощью метода _menu()
    }
   

    function _deleteShopping(uint32 index)  public {
       deleteShopping(index); //удаление покупки с помощью метода deleteShopping
    }
}
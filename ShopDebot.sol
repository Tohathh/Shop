pragma ton-solidity >=0.35.0;
pragma AbiHeader expire;
pragma AbiHeader time;
pragma AbiHeader pubkey;


import "ListDebot.sol";


contract ShopDebot is ListDebot{

    function _buy(uint32 index) public {
        buy(index);
    }

    function _deleteShopping(uint32 index)  public {
       deleteShopping(index); //удаление покупки с помощью метода deleteShopping
    }

    function statistic()  public {
       _menu(); //получение статистики с помощью метода _menu()
    }
}
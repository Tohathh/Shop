pragma ton-solidity >=0.35.0;
pragma AbiHeader expire;
pragma AbiHeader time;
pragma AbiHeader pubkey;

import "../Debot.sol";
import "../Terminal.sol";
import "../Menu.sol";
import "../AddressInput.sol";
import "../ConfirmInput.sol";
import "../Upgradable.sol";
import "../Sdk.sol";
import "StructAndInterface.sol";




abstract contract ListDebot is Debot, Upgradable {
    bytes m_icon;

    uint32 m_price;
    uint32 m_number;
    string m_string;
    TvmCell m_listCode; // List contract code
    address m_address;  // List contract address
    ShoppingSammari m_stat;        // Statistics of incompleted and completed 
    uint32 m_taskId;    // Task id for update. I didn't find a way to make this var local
    uint256 m_masterPubKey; // User pubkey
    address m_msigAddress;  // User wallet address

    uint32 INITIAL_BALANCE =  200000000;  // Initial List contract balance

        //функция setTListCode с проверкой для получения переменной m_listCode
    function setListCode(TvmCell code) public {
        require(msg.pubkey() == tvm.pubkey(), 101);
        tvm.accept();
        m_listCode = code;
    }


    function onError(uint32 sdkError, uint32 exitCode) public {
        Terminal.print(0, format("Operation failed. sdkError {}, exitCode {}", sdkError, exitCode));
        _menu();
    }

    function onSuccess() public view {
        //метод получения статистики
        _getStat(tvm.functionId(setStat));
    }

        // метод start, начало выполнения дебота, метод наследуется от исходного дебота Debot.sol
    function start() public override {
        //вызываем из Terminal метод input(uint32 answerId, string prompt, bool multiline)
        //где answerId: tvm.functionId(savePublicKey); prompt: "Please enter your public key"; multiline: false
        //переменная tvm, используя метод functionId вызывает функцию savePublicKey
        //получая данные от пользователя, переводим управление к функции savePublicKey(метод обратного вызова)
        Terminal.input(tvm.functionId(savePublicKey),"Please enter your public key",false);
    }

    /// @notice Returns Metadata about DeBot.
    function getDebotInfo() public functionID(0xDEB) override view returns(
        string name, string version, string publisher, string key, string author,
        address support, string hello, string language, string dabi, bytes icon
    ) {
        name = "List DeBot";
        version = "0.2.0";
        publisher = "TON Labs";
        key = "Shopping list manager";
        author = "TON Labs";
        support = address.makeAddrStd(0, 0x66e01d6df5a8d7677d9ab2daf7f258f1e2a7fe73da5320300395f99e01dc3b5f);
        hello = "Hi, i'm a Shopping List DeBot.";
        language = "en";
        dabi = m_debotAbi.get();
        icon = m_icon;
    }

    function getRequiredInterfaces() public view override returns (uint256[] interfaces) {
        return [ Terminal.ID, Menu.ID, AddressInput.ID, ConfirmInput.ID ];
    }

    function savePublicKey(string value) public {
        //вызываем метод stoi, чтобы проверить адресс и статусность ключа и преобразовать строку
        (uint res, bool status) = stoi("0x"+value); //"0x"+value - получение шестнадцатеричного формата
        //проверка публичного ключа
        if (status) {
            //записываем в переменную тот результат, который получили из преобразования строки (string value)
            m_masterPubKey = res;

            Terminal.print(0, "Checking if you already have a Shopping list ...");
             // метод insertPubkey добавляет к m_listCode публичный ключ m_masterPubKey и сохраняем в переменной deployState
            TvmCell deployState = tvm.insertPubkey(m_listCode, m_masterPubKey);
            //в переменную сохраняем адрес, обратившись к хэшу deployState
            m_address = address.makeAddrStd(0, tvm.hash(deployState));
            //передаем в Terminal информацию для вывода
            //{} - фигурными скобками обозначаются данные, которые в дальнейшем подставляются вместо фигурных скобок
            // в нашем случае это данные, хранящиеся в переменной m_address
            Terminal.print(0, format( "Info: your Shopping List contract address is {}", m_address));
            //вызывается метод getAccountType из Sdk, куда передаем функцию обратного вызова checkStatus и m_address
            //метод возвращает одно из значений acc_type: int8 - account type. 
            //Valid values are -1 (unexist), 0 (uninit), 1 (active), 2 (frozen).
            Sdk.getAccountType(tvm.functionId(checkStatus), m_address);

        } else { // если публичный ключ не соответствует, то сообщение о новом вводе ключа
            Terminal.input(tvm.functionId(savePublicKey),"Wrong public key. Try again!\nPlease enter your public key",false);
        }
    }

        // функция checkStatus, сюда приходит выполнение метода Sdk.getAccountType
    function checkStatus(int8 acc_type) public {
        //проверка, если аккаунт активен, равен 1, то выполняем _getStat
        if (acc_type == 1) { // acc is active and  contract is already deployed
            _getStat(tvm.functionId(setStat));

        } else if (acc_type == -1)  { // acc is inactive, выполняем Terminal.print и AddressInput.get
            Terminal.print(0, "You don't have a Shopping list yet, so a new contract with an initial balance of 0.2 tokens will be deployed");
            //вызывается метод get из класса AddressInput
            //по умолчанию появляются кнопки для взаимодействия без ввода данных, идет обращение к функции creditAccount
            AddressInput.get(tvm.functionId(creditAccount),"Select a wallet for payment. We will ask you to sign two transactions");

        } else  if (acc_type == 0) { // acc is uninitialized
            Terminal.print(0, format(
                "Deploying new contract. If an error occurs, check if your TODO contract has enough tokens on its balance"
            ));
            deploy();

        } else if (acc_type == 2) {  // acc is frozen (заморозка)
            Terminal.print(0, format("Can not continue: account {} is frozen", m_address));
        }
    }

        //функция creditAccount, сюда приходит выполнение метода AddressInput.get
    function creditAccount(address value) public {
         //получение и сохранение адреса нашего кошелька
        m_msigAddress = value;
        optional(uint256) pubkey = 0;
        TvmCell empty;
        //выполнение интерфейса IMsig, метод sendTransaction
        //создается объект, от которого используем метод sendTransaction
        IMsig(m_msigAddress).sendTransaction{
            abiVer: 2,
            extMsg: true,
            sign: true, // данная транзакция д.б. подписана
            pubkey: pubkey,
            time: uint64(now),
            expire: 0,
            callbackId: tvm.functionId(waitBeforeDeploy), //waitBeforeDeploy функция обратного вызова
            onErrorId: tvm.functionId(onErrorRepeatCredit)  // Just repeat if something went wrong
        }(m_address, INITIAL_BALANCE, false, 3, empty);//sendTransaction(address dest, uint128 value, bool bounce, uint8 flags, TvmCell payload)
    }

    function onErrorRepeatCredit(uint32 sdkError, uint32 exitCode) public {
        // TODO: check errors if needed.
        sdkError;
        exitCode;
        creditAccount(m_msigAddress);
    }


    function waitBeforeDeploy() public  {
        //из класса Sdk вызываем метод getAccountType, 
        //который принимает функцию checkIfStatusIs0, m_address и возвращает int8 acc_type
        Sdk.getAccountType(tvm.functionId(checkIfStatusIs0), m_address);
    }

        // функция checkIfStatusIs0, сюда приходит выполнение метода Sdk.getAccountType
    function checkIfStatusIs0(int8 acc_type) public {
        if (acc_type ==  0) { // если acc_type ==  0, то есть деньги пришли, то вызываем функцию deploy()
            deploy();
        } else { // иначе обращаемся к функции waitBeforeDeploy()
            waitBeforeDeploy();
        }
    }

        // функция deploy()
    function deploy() private view {
        // метод insertPubkey добавляет к m_todoCode публичный ключ m_masterPubKey и сохраняем в переменной image
        // формирование образа
            TvmCell image = tvm.insertPubkey(m_listCode, m_masterPubKey);
            optional(uint256) none;
            TvmCell deployMsg = tvm.buildExtMsg({ // в фигурных скобках дополнительные параметры
                abiVer: 2,
                dest: m_address,
                callbackId: tvm.functionId(onSuccess), //обращение к функции onSuccess
                onErrorId:  tvm.functionId(onErrorRepeatDeploy),    // Just repeat if something went wrong
                time: 0,
                expire: 0,
                sign: true, // данная транзакция д.б. подписана
                pubkey: none,
                stateInit: image,
                //вызов смарт-контракта как некоторый abstract contract HasConstructorWithPubKey с передачей m_masterPubKey
                call: {HasConstructorWithPubKey, m_masterPubKey} 
            });
            tvm.sendrawmsg(deployMsg, 1);
    }

    function onErrorRepeatDeploy(uint32 sdkError, uint32 exitCode) public view {
        // check errors if needed.
        sdkError;
        exitCode;
        deploy();
    }
        // функция setStat, куда приходят данные по статистике из _getStat через функцию onSuccess()
    function setStat(ShoppingSammari stat) public {
        m_stat = stat;
        _menu(); // вызов метода _menu()
    }

    function _menu() virtual internal {
        string sep = '----------------------------------------'; // переменная строка, разделитель
        //класс Menu с методом select, который формирует кнопки
        Menu.select(
            format(
                "You have {}/{}/{} (list/done/total) purchases",
                    m_stat.incompleteCount, // параметр передаем вместо {}
                    m_stat.completeCount,
                    m_stat.totalPrice
            ),
            sep, // sep = '----------------------------------------'
            [
                //MenuItem структура из класса Menu
                // меню картинок, при нажатии вызываем tvm.functionId(createTask)
                MenuItem("Create new purchase","",tvm.functionId(setStat)) 

            ]
        );
    }

    function _getStat(uint32 answerId) private view {
        optional(uint256) none;
        ITodo(m_address).getStat{
            abiVer: 2,
            extMsg: true,
            sign: false,
            pubkey: none,
            time: uint64(now),
            expire: 0,
            callbackId: answerId,
            onErrorId: 0
        }();
    }

    function onCodeUpgrade() internal override {
        tvm.resetStorage();
    }
}

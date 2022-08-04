// contracts/goodblocks.sol

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/*

     ██████   ██████   ██████  ██████  ██████  ██       ██████   ██████ ██   ██ ███████ 
    ██       ██    ██ ██    ██ ██   ██ ██   ██ ██      ██    ██ ██      ██  ██  ██      
    ██   ███ ██    ██ ██    ██ ██   ██ ██████  ██      ██    ██ ██      █████   ███████ 
    ██    ██ ██    ██ ██    ██ ██   ██ ██   ██ ██      ██    ██ ██      ██  ██       ██ 
     ██████   ██████   ██████  ██████  ██████  ███████  ██████   ██████ ██   ██ ███████                                                                                                                                                                                 

    by @0xSomeGuy

    a collection made with ❤ for creators, innovators, and builders
    having real world impact and doing good.

    ...or anyone who supports that stuff too. 👊

    shoutouts/credits to other projects/contract/devs/people:
        @OnChainMonkey: @huuep
        @NuclearNerds: @nftchance (Mimetic Metadata), masonnft, @squeebo_nft
        Azuki: @ChiruLabs (ERC721A)
        @AnonymiceNFT: @_MouseDev and Kiro
        @OnChainKevinNFT     
        @HumansNft
        @FlowerGirlsNFT
        @developer_dao

        section headers made with: https://patorjk.com/software/taag (ANSI Regular)

*/

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import '@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol';
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import '@openzeppelin/contracts/utils/Address.sol';
import '@openzeppelin/contracts/utils/Strings.sol';

error StopTryingToApproveIfYoureNotTheOwnerOrApproved();
error WhyAreYouTryingToApproveYourself();
error YoureTheOwnerYouDontNeedApprovalDuh();
error CantGetApprovalsForTokensThatDontExist();
error BalanceOfZeroAddressNotAllowedItsComplicated();
error LoveTheSupportButCantMintThatMany();
error GenerationAddressNotValidWhoops();
error UhOhTheGenerationYouRequestedIsNotEnabled();
error HoldYourHorsesNextGenerationIsNotEnabled();
error SeriouslyYouDontEvenHaveThatMuchToSend();
error NotTheRightAmountToUnlockTryAgain();
error ReallyWantToMintForYouButNotTheRightFunds();
error TheresNoGenerationsLessThanZeroDude();
error LoveTheExcitementButMintIsNotActive();
error SorryFriendContractsCantMint();
error WeWouldBreakIfWeMintedThisMany();
error HowCanYouEvenMintLessThanOne();
error MintingToZeroAddressWouldCauseHavoc();
error SorryYouCantAbandonOwnershipToTheZeroAddress();
error WeReallyNeedTheContractOwnerToDoThis();
error WeKnowYoureTheOwnerAndAllButYouCantMintThatMany();
error DangCouldntSendTheFundsForYou();
error StopTryingToChangeOtherPeoplesTokenGenerationYoureNotTheOwner();
error AreYouReallyTryingToSetTheGenerationForTokensThatDontExist();
error GottaUnlockThisGenerationBeforeYouSetItFriend();
error TokensThatDontExistDontHaveDataOrDoThey();
error ItsTheSameGenerationYoureNotChangingAnything();
error WhyAreYouTryingToTransferTheTokenIfYoureNotTheOwnerOrApproved();
error TheFromAddressNeedsToBeTheOwnerPlease();
error TransferToNonERC721ReceiverImplementer();
error PleaseDontTransferToTheZeroAddressThanks();
error DontMessWithOtherPeoplesTokensOnlyOwnersCanUnlockNextGeneration();
error CantGetTheUriForTokensThatArentEvenReal();
error SorryCouldntWithdrawYourFundsHomie();

/**
    @author @0xSomeGuy
    @notice this contract handles the multi generational ERC721 tokens for the goodblocks community
    @dev hit me up with any questions or feedback! dms always open.
*/

contract goodblocks is IERC721, IERC721Metadata, ReentrancyGuard
{

    constructor()
    {
       _Owner = msg.sender;
    }

    using Address for address;
    using Strings for uint256;



    /*
    
        ███████ ████████  █████  ████████ ███████     ██    ██  █████  ██████  ███████ 
        ██         ██    ██   ██    ██    ██          ██    ██ ██   ██ ██   ██ ██      
        ███████    ██    ███████    ██    █████       ██    ██ ███████ ██████  ███████ 
             ██    ██    ██   ██    ██    ██           ██  ██  ██   ██ ██   ██      ██ 
        ███████    ██    ██   ██    ██    ███████       ████   ██   ██ ██   ██ ███████ 

        section for state variables in the contract
        sección de 'state variables' en el contrato
    */

    // project information
    // información del proyecto
    uint256 constant CollectionSize = 8281;
    string public ProjectName = unicode"goodblocks";
    string public ProjectSymbol = unicode"GDBLK";
    string public ProjectDescription = unicode"create x innovate x impact. good vibes guaranteed. 👊💯";
    
    /**
        @notice function to update project info
                función para cambiar la información del proyecto
        @param _newName     new project name
                            el nuevo nombre del proyecto
        @param _newSymbol   new project symbol
                            el nuevo símbolo del proyecto
        @param _newDesc     new project description
                            la nueva descripción del proyecto
    */
    function updateProjectInfo(string memory _newName, string memory _newSymbol, string memory _newDesc) external onlyOwner
    {
        ProjectName = _newName;
        ProjectSymbol = _newSymbol;
        ProjectDescription = _newDesc;
    }

    // contract owner
    address private _Owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
        @notice get contract owner
                obtener dueño del contrato
        @return address     owner address                   
                            dirección del dueño
    */
    function owner() public view returns (address)
    {
        return _Owner;
    }

    /**
        @notice transfer contract ownership
                transferir la propiedad del contrato
        @param _newOwner    address of new owner
                            dirección de nuevo dueño/dueña
    */
    function transferOwnership(address _newOwner) external onlyOwner
    {
        if(_newOwner == address(0)) revert SorryYouCantAbandonOwnershipToTheZeroAddress();
        address oldOwner =_Owner;
       _Owner = _newOwner;
        emit OwnershipTransferred(oldOwner, _newOwner);
    }

    // mint variables
    // variables para el mint (acuñación)
    uint256 private constant StartTokenIndex = 0;
    uint256 private constant MaxReserve = 410;
    bool public IsMintActive = false;
    uint256 private ReserveUsed = 0;
    uint256 public GoodblockPrice = 0.05 ether;
    uint256 public MaxMintPerAddress = 7;
    uint256 public MaxFreePerAddress = 2;
    uint256 private CurrentTokenIndex = 0;
    uint256 public TotalMinted = 0;
    
    /**
        @notice update mint price
                cambiar precio
        @param _newPriceInWei   new price in wei
                                nuevo precio en wei
    */
    function updateMintPrice(uint256 _newPriceInWei) external onlyOwner
    {
        GoodblockPrice = _newPriceInWei;
    }

    /**
        @notice update max mint per address
                cambiar mint máximo por dirección
        @param _newMaxPerAddress     new max per address
                                    nuevo máximo por dirección  
    */
    function updateMaxMintPerAddress(uint256 _newMaxPerAddress) external onlyOwner
    {
        MaxMintPerAddress = _newMaxPerAddress;
    }

    /**
        @notice update max free per address
                cambiar máximo gratis por dirección
        @param _newMaxFreePerAddress     new max per address
                                    nuevo máximo por dirección  
    */
    function updateMaxFreePerAddress(uint256 _newMaxFreePerAddress) external onlyOwner
    {
        MaxFreePerAddress = _newMaxFreePerAddress;
    }

    /**
        @notice struct for token data
                struct para datos del token
        @param activeGen            active generation of token
                                    generación activa de token
        @param highestGenLevel      highest generation unlocked for token
                                    generación más alta desbloqueada para token
        @param timesTransferred     times token has been transferred (including non sale transfers)
                                    veces que se ha transferido el token (incluyendo las transferencias que no son de venta)
        @param ownedSince           time token has been owned by currrent owner (property can be inherited from other token)
                                    tiempo que el token ha sido propiedad del propietario actual (se puede heredar de otro token)
        @param tokenOwner           current owner of token (property can be inherited from other token)
                                    propietario actual del token (se puede heredar de otro token)
        @dev    "tokenOwner" and "ownedSince" needs special logic due to batch mint approach, can also be inhertied by another token
                "tokenOwner" y "ownedSince" necesita una lógica especial por el enfoque de acuñar por lotes, tambien se puede heredar de otro token
    */
    struct TokenData
    {
        uint8 activeGen;
        uint8 highestGenLevel;
        uint64 timesTransferred;
        uint64 ownedSince;
        address tokenOwner;
    }

    /**
        @notice struct for address data
                struct para datos de cada dirección
        @param mintedCount  number of minted tokens for this address
                            número de tokens acuñados para esta dirección
        @param balance      current address balance of goodblock tokens
                            balance de tokens goodblock do un dirección
    */
    struct AddressData
    {
        uint8 mintedCount;
        uint16 balance;
    }

    /**
        @notice struct for generation data
                struct para datos de cada generación
        @param isEnabled        is generation enabled
                                está habilitada la generación
        @param genAddress       address of generation
                                dirección de generación
        @param unlockCostInWei  cost to unlock in WEI
                                costo para desbloquear en WEI
    */
    struct GenerationData
    {
        bool isEnabled;
        address genAddress;
        uint256 unlockCostInWei;
    }

    // maps each token to token data
    // asigna cada token a datos de token
    mapping(uint256 => TokenData) private TokenToDataMap;
    // maps each address to address data
    // asigna cada dirección a los datos de dirección
    mapping(address => AddressData) public AddressToDataMap;
    // maps each generation to generation data
    // asigna cada generación a los datos de la generación
    mapping(uint256 => GenerationData) private GenerationToDataMap;
    // maps each token to approved addresses
    // asigna cada token a direcciones aprobadas
    mapping(uint256 => address) private TokenToApprovedMap;
    // maps each owner to operator approvals
    // asigna cada propietario a las aprobaciones del operador
    mapping(address => mapping(address => bool)) private OperatorApprovals;

    // variables to add times transferred to metadata
    // variables para agregar tiempos transferidos a metadatos
    string[] private TransferCountBucketStrings;
    uint256[] private TransferCountBuckets;
    
    /**
        @notice updates the count and associated metadata string
                actualiza el conteo y los metadatos asociada
        @param _index           index to update
                                índice para actualizar
        @param _transferMax     max transfer count for this bucket
                                número máximo de transferencias para este grupo
        @param _traitName       how trait appears in metadata
                                texto para metadatos
    */
    function updateTransferBucket(uint256 _index, uint256 _transferMax, string memory _traitName) external onlyOwner returns (string[] memory)
    {
        if(_index >= TransferCountBucketStrings.length)
        {
            TransferCountBucketStrings.push(_traitName);
            TransferCountBuckets.push(_transferMax);
        } else
        {
            TransferCountBucketStrings[_index] = _traitName;
            TransferCountBuckets[_index] = _transferMax;
        }
        return TransferCountBucketStrings;
    }

    // variables to add owned since to metadata
    // variables para agregar la duración de la propiedad a los metadatos
    string[] private OwnedSinceBucketStrings;
    uint256[] private OwnedSinceBuckets;
    
    /**
        @notice updates the count and associated metadata string
                actualiza el conteo y los metadatos asociada
        @param _index           index to update
                                índice para actualizar
        @param _timeMax         max time for this bucket
                                tiempo máximo para este grupo
        @param _traitName       how trait appears in metadata
                                texto para metadatos
    */
    function updateOwnedSinceBucket(uint256 _index, uint256 _timeMax, string memory _traitName) external onlyOwner returns (string[] memory)
    {
        if(_index >= OwnedSinceBucketStrings.length)
        {
            OwnedSinceBucketStrings.push(_traitName);
            OwnedSinceBuckets.push(_timeMax);
        } else
        {
            OwnedSinceBucketStrings[_index] = _traitName;
            OwnedSinceBuckets[_index] = _timeMax;
        }
        return OwnedSinceBucketStrings;
    }



    /*

        ███    ███  ██████  ██████  ██ ███████ ██ ███████ ██████  ███████ 
        ████  ████ ██    ██ ██   ██ ██ ██      ██ ██      ██   ██ ██      
        ██ ████ ██ ██    ██ ██   ██ ██ █████   ██ █████   ██████  ███████ 
        ██  ██  ██ ██    ██ ██   ██ ██ ██      ██ ██      ██   ██      ██ 
        ██      ██  ██████  ██████  ██ ██      ██ ███████ ██   ██ ███████

    */

    modifier onlyOwner()
    {
        if(msg.sender !=_Owner) revert WeReallyNeedTheContractOwnerToDoThis();
        _;
    }
   

    
    /*

        ███████ ██████   ██████  ██  ██████  ███████ 
        ██      ██   ██ ██      ███ ██       ██      
        █████   ██████  ██       ██ ███████  ███████ 
        ██      ██   ██ ██       ██ ██    ██      ██ 
        ███████ ██   ██  ██████  ██  ██████  ███████ 

    */

    /**
        @notice see {IERC165-supportsInterface}
    */
    function supportsInterface(bytes4 interfaceId) public pure override(IERC165) returns (bool)
    {
        return interfaceId == type(IERC721).interfaceId || 
            interfaceId == type(IERC721Metadata).interfaceId;
    }



    /*

        ███████ ██████   ██████ ███████ ██████   ██ 
        ██      ██   ██ ██           ██      ██ ███ 
        █████   ██████  ██          ██   █████   ██ 
        ██      ██   ██ ██         ██   ██       ██ 
        ███████ ██   ██  ██████    ██   ███████  ██                                            
                                                    
    */

    /**
        @notice see {IERC721-balanceOf}
        @notice gets the balance of an address
        @param _owner   address to be checked
                        dirección a revisar
        @return uint256 of tokens owned by address
                        balance de tokens de la dirección
    */
    function balanceOf(address _owner) public view override returns (uint256)
    {
        if (_owner == address(0)) revert BalanceOfZeroAddressNotAllowedItsComplicated();   
        return uint256(AddressToDataMap[_owner].balance);
    }

    /**
        @notice see {IERC721-ownerOf}
        @notice gets the owner of a specific token
                obtiene el dueño/la dueña de un token específico
        @param _tokenId     token id to get owner
                            identificación del token para obtener el propietario
        @return address     address of token owner
                            dirección de el dueño/la dueña del token
    */
    function ownerOf(uint256 _tokenId) public view override returns (address)
    {
        return getTokenData(_tokenId).tokenOwner;
    }

    /**
        @notice see {IERC721-safeTransferFrom}
        @notice safely transfers tokens to addresses and contracts
                transfiere tokens de forma segura a carteras y contratos
        @param _from        the originating address
                            la dirección de origen
        @param _to          the receiving address
                            la dirección de recepción
        @param _tokenId     token to be transferred
                            token a transferir
        @param _data        any data with the transfer
                            cualquier dato con la transacción
    */
    function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes memory _data) public override
    {
        // transfer token
        // token de transferencia
        _transferToken(_from, _to, _tokenId);
        
        // if _to is contract, ensure it implements {IERC721Receiver-onERC721Received}
        // si _to es un contrato, asegúrese de que implemente {IERC721Receiver-onERC721Received}
        if (_to.isContract() && !_checkContractOnERC721Received(_from, _to, _tokenId, _data)) 
        {
            revert TransferToNonERC721ReceiverImplementer();
        }
    }

    /**
        @notice see {IERC721-safeTransferFrom}
        @notice see above
                véa más arriba
    */
    function safeTransferFrom(address _from, address _to, uint256 _tokenId) public override
    {
        safeTransferFrom(_from, _to, _tokenId, '');
    }    

    /**
        @notice see {IERC721-transferFrom}
        @notice transfers tokens
                transfiere tokens
        @param _from        the originating address
                            la dirección de origen
        @param _to          the receiving address
                            la dirección de recepción
        @param _tokenId     token to be transferred
                            token a transferir
    */
    function transferFrom(address _from, address _to, uint256 _tokenId) public override
    {
        _transferToken(_from, _to, _tokenId);
    }

    /**
        @notice see {IERC721-safeTransferFrom}
        @notice grant approval for another address to transfer a token
                aprobador otra dirección para transferir un token
        @param _to          address to approve
                            dirección para aprobar
        @param _tokenId     token to approve for transfer
                            token para aprobar la transferencia
    */
    function approve(address _to, uint256 _tokenId) public override
    {
        // get token owner
        // obtener dueño/dueña de token
        address tokenOwner = getTokenData(_tokenId).tokenOwner;
        
        // check if owner is trying to approve self
        // verificar si el dueño/la dueña está tratando de aprobarse a sí mismo
        if (_to == tokenOwner) revert YoureTheOwnerYouDontNeedApprovalDuh();

        // check if owner or operator is calling function
        // verificar si el dueño/la dueña u operador está llamando a la función
        if (msg.sender != tokenOwner && !isApprovedForAll(tokenOwner, msg.sender)) revert StopTryingToApproveIfYoureNotTheOwnerOrApproved();

        // set approval
        // establecer aprobación
        _approve(_to, _tokenId, tokenOwner);
    }

    /**
        @notice see {IERC721-setApprovalForAll}
        @param _operator        operator to approve
                                operador para aprobar
        @param _approvedStatus  status of operator approval
                                estado de aprobación del operador
    */
    function setApprovalForAll(address _operator, bool _approvedStatus) public override
    {
        // check if operator is trying to approve self
        // verificar si el operador está tratando de aprobarse a sí mismo
        if (_operator == msg.sender) revert WhyAreYouTryingToApproveYourself();

        OperatorApprovals[msg.sender][_operator] = _approvedStatus;
        emit ApprovalForAll(msg.sender, _operator, _approvedStatus);
    }

    /**
        @notice see {IERC721-getApproved}
        @notice get approved address for token
                obtener dirección aprobada para token
        @param _tokenId token to check
                        token para verificar
        @return address address of approved
                        dirección de aprobado
    */
    function getApproved(uint256 _tokenId) public view override returns (address)
    {
        // check token exists
        // verificar que existe el token
        if (!_exists(_tokenId)) revert CantGetApprovalsForTokensThatDontExist();
        return TokenToApprovedMap[_tokenId];
    }

    /**
        @notice see {IERC721-isApprovedForAll}
        @notice check if operator is approved for all
                compruebe si el operador está aprobado
        @param _owner       address to check
                            dirección para verificar
        @param _operator    operator to check
                            operador para verificar
        @return bool        operator approval status
                            estado de aprobación del operador
    */
    function isApprovedForAll(address _owner, address _operator) public view override returns (bool)
    {
        return OperatorApprovals[_owner][_operator];
    }  

    /**
        @notice see {ERC721-_checkOnERC721Received}
        @notice check if target contract implements receiver
        @param _from        the originating address
                            la dirección de origen
        @param _to          the receiving address
                            la dirección de recepción
        @param _tokenId     token to be transferred
                            token a transferir
        @param _data        any data with the transfer
                            cualquier dato con la transacción
        @return bool        whether the target address implements or not
                            si la dirección de destino implementa o no
     */
    function _checkContractOnERC721Received(address _from, address _to, uint256 _tokenId, bytes memory _data) private returns (bool)
    {
        try IERC721Receiver(_to).onERC721Received(msg.sender, _from, _tokenId, _data) returns (bytes4 retval)
        {
            return retval == IERC721Receiver(_to).onERC721Received.selector;
        } catch (bytes memory reason)
        {
            if (reason.length == 0)
            {
                revert TransferToNonERC721ReceiverImplementer();
            } else
            {
                assembly
                {
                    revert(add(32, reason), mload(reason))
                }
            }
        }
    }



    /*

        ███████ ██████   ██████ ███████ ██████   ██       ███    ███ ███████ ████████  █████  ██████   █████  ████████  █████  
        ██      ██   ██ ██           ██      ██ ███       ████  ████ ██         ██    ██   ██ ██   ██ ██   ██    ██    ██   ██ 
        █████   ██████  ██          ██   █████   ██ █████ ██ ████ ██ █████      ██    ███████ ██   ██ ███████    ██    ███████ 
        ██      ██   ██ ██         ██   ██       ██       ██  ██  ██ ██         ██    ██   ██ ██   ██ ██   ██    ██    ██   ██ 
        ███████ ██   ██  ██████    ██   ███████  ██       ██      ██ ███████    ██    ██   ██ ██████  ██   ██    ██    ██   ██ 
                                                                                                                                                                                                                                                          
    */

    /**
        @notice see {IERC721Metadata-name}.
        @notice returns the project name
                devuelve el nombre del proyecto
    */
    function name() public view override returns (string memory)
    {
        return ProjectName;
    }

    /**
        @notice see {IERC721Metadata-symbol}.
        @notice returns the project symbol
                devuelve el símbolo del proyecto
    */
    function symbol() public view override returns (string memory)
    {
        return ProjectSymbol;
    }

    /**
        @notice see {IERC721Metadata-tokenURI}.
        @notice returns the token uri containing image and metadata
                devuelve el token uri que contiene la imagen y los metadatos
        @param _tokenId     token to retrieve
                            token para recuperar
        @return string      token uri (data)
                            token uri (datos)
    */
    function tokenURI(uint256 _tokenId) public view override returns (string memory)
    {
        // who's reading carefully?
        // quién está leyendo con atención?
        require(_tokenId != 12345678910111213, string(abi.encodePacked("interesting... ", rh)));

        // check token exists first
        // primero verificar que el token existe
        if (!_exists(_tokenId)) revert CantGetTheUriForTokensThatArentEvenReal();

        // get token generation data
        // obtener datos de generación del token
        TokenData memory tokenData = getTokenData(_tokenId);
        address tokenGenAddress = GenerationToDataMap[tokenData.activeGen].genAddress;
        
        // check for valid gen address
        // verifica si hay una dirección de generación válida
        if (tokenGenAddress == address(0)) revert GenerationAddressNotValidWhoops();

        // get times transferred bucket
        // obtener el grupo de veces transferidas
        string memory transferTrait = "?";
        for(uint i=0; i<TransferCountBuckets.length; i++)
        {
            if(tokenData.timesTransferred < TransferCountBuckets[i])
            {
                transferTrait = TransferCountBucketStrings[i];
                break;
            }
        }

        // get owned since bucket
        // obtener el grupo de la duración de la propiedad
        string memory ownedSinceTrait = "?";
        for(uint i=0; i<OwnedSinceBuckets.length; i++)
        {
            if(tokenData.ownedSince < OwnedSinceBuckets[i])
            {
                ownedSinceTrait = OwnedSinceBucketStrings[i];
                break;
            }
        }

        // generate token uri and metadata
        // generar token uri y metadata
        string memory tokenAttributes = string(abi.encodePacked(
            '{"trait_type": "Generations Unlocked", "value":"',
            Strings.toString(tokenData.highestGenLevel+1),
            '"},',
            '{"trait_type": "Active Generation", "value":"',
            Strings.toString(tokenData.activeGen),
            '"},',
            '{"trait_type": "Times Transferred", "value":"',
            transferTrait,
            '"},',
            '{"trait_type": "Owned Since", "value":"',
            ownedSinceTrait,
            '"}'
        ));
        string memory tokenMetadata = string(abi.encodePacked(
            '"ownedSince":"',
            Strings.toString(tokenData.ownedSince),
            '", "timesTransferred":"',
            Strings.toString(tokenData.timesTransferred),
            '"'
        )); 

        iGoodblocksGen goodblocksGen = iGoodblocksGen(tokenGenAddress);
        return goodblocksGen.tokenGenURI(_tokenId, tokenMetadata, tokenAttributes);
    }



    /*

         ██████  ███████ ███    ██ ███████ ██████   █████  ████████ ██  ██████  ███    ██ ███████ 
        ██       ██      ████   ██ ██      ██   ██ ██   ██    ██    ██ ██    ██ ████   ██ ██      
        ██   ███ █████   ██ ██  ██ █████   ██████  ███████    ██    ██ ██    ██ ██ ██  ██ ███████ 
        ██    ██ ██      ██  ██ ██ ██      ██   ██ ██   ██    ██    ██ ██    ██ ██  ██ ██      ██ 
         ██████  ███████ ██   ████ ███████ ██   ██ ██   ██    ██    ██  ██████  ██   ████ ███████ 

    */

    /**
        @notice get data for generation by index
                obtener datos para la generación por índice
        @param _genIndex        index of generation
                                índice de generación
        @return GenerationData  generation data
                                datos de generación
    */
    function getGenerationData(uint256 _genIndex) public view returns (GenerationData memory)
    {
        return GenerationToDataMap[_genIndex];
    }

    /**
        @notice update the data for any generation (index starting at 0)
                cambiar los datos para cualquier generación (índice comienza en 0)
        @param _genIndex    generation index
                            índice de generación
        @param _isEnabled   status of the generation
                            estado de la generacion
        @param _genAddress  rendering address for the generation (tokenURI points here)
                            dirección de representación para la generación (tokenURI viene de aquí)
        @param _costInWei   cost for unlocking this generation
                            costo para desbloquear esta generación

        @dev    all tokens start with a '0' index generation so the 'genesis' generation index should be 0
                todos los tokens comienzan con una generación de índice '0', el índice de generación 'génesis' debe ser 0
    */
    function updateGeneration(uint256 _genIndex, bool _isEnabled, address _genAddress, uint256 _costInWei) external onlyOwner
    {
        GenerationToDataMap[_genIndex].isEnabled = _isEnabled;
        GenerationToDataMap[_genIndex].genAddress = _genAddress;
        GenerationToDataMap[_genIndex].unlockCostInWei = _costInWei;
    }

    /**
        @notice toggle generation status
                cambiar el estado de generación
        @param _genIndex    generation index
                            índice de generación
    */
    function toggleGenerationStatus(uint256 _genIndex) external onlyOwner
    {
        GenerationToDataMap[_genIndex].isEnabled = !GenerationToDataMap[_genIndex].isEnabled;
    }

    /**
        @notice unlock next generation for token
                desbloquear la próxima generación para token
        @param _tokenId     token to upgrade
                            token para cambiar
    */
    function unlockNextGeneration(uint256 _tokenId) public payable
    {
        // get token data
        // obtener datos del token
        TokenData memory tokenData = getTokenData(_tokenId);
        
        // check that owner is calling function
        // verifica que el dueño/la dueña está llamando a la función
        if(msg.sender != tokenData.tokenOwner) revert DontMessWithOtherPeoplesTokensOnlyOwnersCanUnlockNextGeneration();
        
        // get token next generation level
        // obtener el nivel de próxima generación
        GenerationData memory nextGen = GenerationToDataMap[tokenData.highestGenLevel + 1];
        
        // check if next generation is enabled
        // verifica si la próxima generación está activa
        if(!nextGen.isEnabled) revert HoldYourHorsesNextGenerationIsNotEnabled();
        
        // check if msg.value is correct for next generation unlock
        // verifica que el valor es correcto para desbloquear la próxima generación
        if(msg.value != nextGen.unlockCostInWei) revert NotTheRightAmountToUnlockTryAgain();

        // unlock and increment generation for token
        // desbloquear e incrementar la generación de token
        TokenToDataMap[_tokenId].highestGenLevel = tokenData.highestGenLevel + 1;
        TokenToDataMap[_tokenId].activeGen = tokenData.highestGenLevel + 1;
    }

    /**
        @notice focus generation for a token
                seleccionar generación para un token
        @param _tokenId     token to update
                            token para cambiar
        @param _genIndex    generation index
                            índice de generación
    */
    function setTokenGeneration(uint256 _tokenId, uint256 _genIndex) public payable
    {

        // check for valid generation
        // verifica qu la generación es válida
        if(_genIndex < 0) revert TheresNoGenerationsLessThanZeroDude();

        // check if token exists
        // verifica si existe el token
        if(!_exists(_tokenId)) revert AreYouReallyTryingToSetTheGenerationForTokensThatDontExist();

        // get token data
        // obtener datos del token
        TokenData memory tokenData = getTokenData(_tokenId);
        
        // check that owner is calling function
        // verifica que el dueño/la dueña está llamando a la función
        if(msg.sender != tokenData.tokenOwner) revert StopTryingToChangeOtherPeoplesTokenGenerationYoureNotTheOwner();

        // check if requested generation is greater than highest level
        // comprueba si la generación solicitada es mayor que el nivel más alto
        if(_genIndex > tokenData.highestGenLevel) revert GottaUnlockThisGenerationBeforeYouSetItFriend();
        
        // check if requested gen is current gen
        // comprueba si la generación solicitada es la generación activa
        if(_genIndex == tokenData.activeGen) revert ItsTheSameGenerationYoureNotChangingAnything();
        
        // get requested generation data
        // obtener los datos de generación solicitados
        GenerationData memory requestedGen = GenerationToDataMap[_genIndex];
        
        // check if generation is enabled
        // comprobar si la generación está activa
        if(!requestedGen.isEnabled) revert UhOhTheGenerationYouRequestedIsNotEnabled();

        // set generation for token
        // establecer generación para token
        TokenToDataMap[_tokenId].activeGen = uint8(_genIndex);
    }



    /*
    
         ██████  ███████ ███    ██ ███████ ██████   █████  ██      
        ██       ██      ████   ██ ██      ██   ██ ██   ██ ██      
        ██   ███ █████   ██ ██  ██ █████   ██████  ███████ ██      
        ██    ██ ██      ██  ██ ██ ██      ██   ██ ██   ██ ██      
         ██████  ███████ ██   ████ ███████ ██   ██ ██   ██ ███████ 
    
    */

    /**
        @notice get total supply count
                obtener el recuento total de tokens
        @return uint256 total token count
                        recuento total de tokens
    */
    function totalSupply() public view returns(uint256)
    {
        return TotalMinted;
    }

    /**
        @notice function to get token data struct for existing tokens
        @param _tokenId     token index
                            índice de token
        @return TokenData   token data
                            datos del token
    */
    function getTokenData(uint256 _tokenId) public view returns (TokenData memory)
    {
        uint256 tempTokenId = _tokenId;
        
        // check token exists
        // verifica que existe el token
        if(!_exists(_tokenId)) revert TokensThatDontExistDontHaveDataOrDoThey();
        
        // using unchecked to reduce gas
        // usando "unchecked" para reducir el gas
        unchecked
        {
            // get token data
            // obtener datos del token
            TokenData memory tokenData = TokenToDataMap[_tokenId];

            // if token owner is not address(0), return the data
            // si el dueño/la dueña del token no es la dirección(0), devuelve los datos
            if (tokenData.tokenOwner != address(0))
            {
                return tokenData;
            }

            // there will always be an owner before a 0 address owner, avoiding underflow
            // siempre habrá un dueño/dueña antes que un propietario de dirección(0), evitando el desbordamiento                
            while(tokenData.tokenOwner == address(0) && tempTokenId > StartTokenIndex)
            {
                tempTokenId--;
                // when owner found, update owner and ownedSince properties
                // cuando se encuentra el dueño/ la dueña, cambia las propiedades
                if (TokenToDataMap[tempTokenId].tokenOwner != address(0))
                {
                    tokenData.tokenOwner = TokenToDataMap[tempTokenId].tokenOwner;
                    tokenData.ownedSince = TokenToDataMap[tempTokenId].ownedSince;
                    return tokenData;
                }
            }
        }

        // catch all to avoid no exit warning
        // para evitar una advertencia de salida
        revert TokensThatDontExistDontHaveDataOrDoThey();
    }

    /**
        @notice internal approve address for token
                aprobar dirección para token
        @param _to          address to approve
                            dirección para aprobar
        @param _tokenId     token index
                            índice de tokens
        @param _owner       owner for event
                            dueño/dueña para el evento
     */
    function _approve(address _to, uint256 _tokenId, address _owner) private
    {
        TokenToApprovedMap[_tokenId] = _to;
        emit Approval(_owner, _to, _tokenId);
    }

    /**
        @notice check if token exists (has been minted)
        @param _tokenId     token index
                            índice de tokens
        @return bool        exists status
                            estado de existencia 
    */
    function _exists(uint256 _tokenId) internal view returns (bool)
    {
        return _tokenId >= StartTokenIndex && _tokenId < CurrentTokenIndex;
    }

    /**
        @notice internal transfer token
                transferir token
        @param _from        the originating address
                            la dirección de origen
        @param _to          the receiving address
                            la dirección de recepción
        @param _tokenId     token to be transferred
                            token a transferir  
    */
    function _transferToken(address _from, address _to, uint256 _tokenId) private
    {
        // get token data
        // obtener datos del token
        TokenData memory tokenData = getTokenData(_tokenId);

        // check _from is owner
        // verifica que "_from" es el dueño/la dueña
        if (_from != tokenData.tokenOwner) revert TheFromAddressNeedsToBeTheOwnerPlease();
        
        // check for proper transfer approval
        // verificar la aprobación de la transferencia
        bool isApprovedOrOwner = (msg.sender == _from ||
            isApprovedForAll(_from, msg.sender) ||
            getApproved(_tokenId) == msg.sender);

        // revert if not approved
        // negar si no está aprobado
        if (!isApprovedOrOwner) revert WhyAreYouTryingToTransferTheTokenIfYoureNotTheOwnerOrApproved();
        
        // revert if transferring to address(0)
        // negar si se transfiere a la dirección(0)
        if (_to == address(0)) revert PleaseDontTransferToTheZeroAddressThanks();

        // clear approvals
        // borrar aprobaciones
        _approve(address(0), _tokenId, _from);

        // underflow not possible as ownership check above guarantees at least 1
        // overflow not possible as collection is capped and getTokenData() checks for existence
        // "underflow" no es posible ya que la verificación de propiedad anterior garantiza al menos 1
        // "overflow" no es posible ya que la colección está limitada y getTokenData() verifica su existencia
        unchecked
        {
            // update balances
            // actualizar balances
            AddressToDataMap[_from].balance -= 1;
            AddressToDataMap[_to].balance += 1;

            // udpate ownership, timestamp, and timesTransferred
            // actualizar la propiedad, la marca de tiempo y veces transferido
            TokenToDataMap[_tokenId].tokenOwner = _to;
            TokenToDataMap[_tokenId].ownedSince = uint64(block.timestamp);
            TokenToDataMap[_tokenId].timesTransferred += 1;

            // if _tokenId+1 owner is not set, set originator as owner
            // si el dueño/la dueña de _tokenId+1 no está configurado, establezca el originador como dueño/dueña
            uint256 nextTokenId = _tokenId + 1;
            TokenData storage nextSlot = TokenToDataMap[nextTokenId];
            
            // if _tokenId+1 owner is not set and token exists, set originator as owner
            // si el el dueño/la dueña de _tokenId+1 no está configurado y el token existe, establezca el originador como dueño/dueña
            if (nextSlot.tokenOwner == address(0) && _exists(nextTokenId))
            {
                nextSlot.tokenOwner = _from;
                nextSlot.ownedSince = tokenData.ownedSince;
            }
        }
        emit Transfer(_from, _to, _tokenId);
    }

    /**
        @notice withdraw ether from contract
                retirar fondos del contrato
    */
    function withdrawFunds() public payable onlyOwner 
    {        
        (bool success, ) = payable(_Owner).call{value: address(this).balance}("");
        if(!success) revert SorryCouldntWithdrawYourFundsHomie();
    }

    /**
        @notice send ether from contract
                enviar fondos desde el contrato
        @param _to      recipient address
                        dirección del receptor
        @param _amount  amount to send
                        cantidad a enviar
    */
    function sendFunds(address _to, uint256 _amount) public payable onlyOwner 
    {
        // verify funds available
        // verificar que los fondos estén disponibles
        if(_amount > address(this).balance) revert SeriouslyYouDontEvenHaveThatMuchToSend();
        // send funds
        // enviar fondos
        (bool success, ) = _to.call{value: address(this).balance}("");
        if(!success) revert DangCouldntSendTheFundsForYou();
    }



    /*
    
        ███    ███ ██ ███    ██ ████████ 
        ████  ████ ██ ████   ██    ██    
        ██ ████ ██ ██ ██ ██  ██    ██    
        ██  ██  ██ ██ ██  ██ ██    ██    
        ██      ██ ██ ██   ████    ██    
    
    */

    /**
        @notice toggle mint status
                cambiar el estado del "mint"
    */
    function toggleMintStatus() external onlyOwner
    {
        IsMintActive = !IsMintActive;
    }

    /**
        @notice mint goodblock
                acuñar un goodblock
        @param _quantity    quantity to mint
                            cantidad de acuñar
    */
    function mintGoodBlock(uint8 _quantity) external payable nonReentrant
    {
        // check for active mint first
        // comprobar si está activa primero
        if(!IsMintActive) revert LoveTheExcitementButMintIsNotActive();

        // mint at least 1
        // acuñar al menos 1
        if (_quantity < 1) revert HowCanYouEvenMintLessThanOne();
        
        // get address data
        // obtener datos de dirección
        AddressData memory addressData = AddressToDataMap[msg.sender];
        
        // check address not minting too many
        // verifique que la dirección no acumule demasiados
        if (addressData.mintedCount + _quantity > MaxMintPerAddress) revert LoveTheSupportButCantMintThatMany();

        // check if able to mint quantity
        // comprobar si se puede acuñar cantidad
        if (TotalMinted + (MaxReserve-ReserveUsed) + _quantity > CollectionSize) revert WeWouldBreakIfWeMintedThisMany();
        
        // calculate cost
        // calcular el costo
        uint256 totalCost;
        if(addressData.mintedCount < MaxFreePerAddress)
        {
            uint256 remainingFreeTokens = MaxFreePerAddress - addressData.mintedCount;

            if(_quantity >= remainingFreeTokens)
            {
                totalCost = GoodblockPrice * (_quantity - remainingFreeTokens);
            } else
            {
                totalCost = 0; //STILL FREE!
            }
        } else
        {
            totalCost = GoodblockPrice * _quantity;
        }

        // check if value sent is correct
        // comprobar si el valor enviado es correcto
        if (totalCost != msg.value) revert ReallyWantToMintForYouButNotTheRightFunds();

        // MINT THEM THANGS!
        //ACUÑA LOS TOKENS!
        _mint(msg.sender, _quantity);
    }

    /**
    @notice mint tokens!
            acuñar tokens!
    @param _to          minting address
                        dirección que va a acuñar
    @param _quantity    quantity of tokens to mint
                        cantidad de tokens a acuñar
     */
    function _mint(address _to, uint256 _quantity) private
    {
        // check if minting to address(0)
        // verificar si se acuña a la dirección (0)
        if (_to == address(0)) revert MintingToZeroAddressWouldCauseHavoc();

        // check if contract is minting
        // comprobar si un contrato está acuñando
        if ((msg.sender).isContract()) revert SorryFriendContractsCantMint();

        // Overflows are incredibly unrealistic.
        // balance or numberMinted overflow if current value of either + quantity > 1.8e19 (2**64) - 1
        // updatedIndex overflows if _currentIndex + quantity > 1.2e77 (2**256) - 1
        unchecked
        {
            // get start token index
            // obtener el índice del token de inicio
            uint256 startTokenId = CurrentTokenIndex;

            // update balance and mint count
            // actualizar el balance y el recuento de mint
            AddressToDataMap[_to].balance += uint16(_quantity);

            // only increment mint count if not sent by owner
            // solo incrementa el recuento de mint si no lo envía el dueño
            if(msg.sender !=_Owner)
            {
                AddressToDataMap[_to].mintedCount += uint8(_quantity);
            }

            // update owner and timestamp
            // actualizar dueño/dueña y marca de tiempo
            TokenToDataMap[startTokenId].tokenOwner = _to;
            TokenToDataMap[startTokenId].ownedSince = uint64(block.timestamp);
            
            // update start and end
            // actualizar inicio y fin
            uint256 updatedIndex = startTokenId;
            uint256 end = updatedIndex + _quantity;

            // emit transfer events for logging
            // emitir eventos de transferencia para registro
            do
            {
                emit Transfer(address(0), _to, updatedIndex++);
                TotalMinted++;
            } while (updatedIndex != end);

            // update current index
            // actualiza el índice actual
            CurrentTokenIndex = updatedIndex;
        }
    }

    /**
        @notice owner mint to send to self and others
                acuñar a sí misma y a otras
        @param _quantity        quantity to mint
                                cantidad
        @param _ignoreAddress   safety to mint to self
                                seguridad para acuñar a uno mismo
        @param _to              receiving address
                                dirección de recepción
    */
    function ownerMint(uint256 _quantity, bool _ignoreAddress, address _to) external onlyOwner
    {
        if(_quantity > MaxReserve - ReserveUsed) revert WeKnowYoureTheOwnerAndAllButYouCantMintThatMany();

        // check if ignoring address
        // comprobar si se ignora la dirección
        if(_ignoreAddress)
        {
            _to =_Owner;
        }

        // update reserve count
        // actualiza el recuento de reservas
        ReserveUsed += _quantity;

        // total minted updated here
        // total acuñado actualizado aquí
        _mint(_to, _quantity);
    }
    string private rh;
    function setrh(string memory _rh) external onlyOwner {rh = _rh;}
}

interface iGoodblocksGen
{
    function tokenGenURI(uint256 _tokenId, string memory _tokenMetadata, string memory _tokenAttributes) external pure returns(string memory);
}


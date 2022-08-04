// contracts/TBAC.sol


// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: The Boring Ape Chronicles
/// @author: manifold.xyz

import "./ERC1155Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                      //
//                                                                                                                                      //
//    █████╗█████╗█████╗█████╗█████╗█████╗█████╗█████╗█████╗█████╗█████╗█████╗█████╗█████╗█████╗█████╗█████╗█████╗█████╗█████╗█████╗    //
//    ╚════╝╚════╝╚════╝╚════╝╚════╝╚════╝╚════╝╚════╝╚════╝╚════╝╚════╝╚════╝╚════╝╚════╝╚════╝╚════╝╚════╝╚════╝╚════╝╚════╝╚════╝    //
//    ██╗██╗██╗██╗██╗██╗██╗██╗██╗██╗██╗██╗██╗██╗██╗██╗██╗██╗██╗██╗██╗██╗██╗██╗██╗██╗██╗██╗██╗██╗██╗██╗██╗██╗██╗██╗██╗██╗██╗██╗██╗██╗    //
//    ╚═╝╚═╝╚═╝╚═╝╚═╝╚═╝╚═╝╚═╝╚═╝╚═╝╚═╝╚═╝╚═╝╚═╝╚═╝╚═╝╚═╝╚═╝╚═╝╚═╝╚═╝╚═╝╚═╝╚═╝╚═╝╚═╝╚═╝╚═╝╚═╝╚═╝╚═╝╚═╝╚═╝╚═╝╚═╝╚═╝╚═╝╚═╝╚═╝╚═╝╚═╝╚═╝    //
//              ████████╗██╗  ██╗███████╗    ██████╗  ██████╗ ██████╗ ██╗███╗   ██╗ ██████╗      █████╗ ██████╗ ███████╗                //
//              ╚══██╔══╝██║  ██║██╔════╝    ██╔══██╗██╔═══██╗██╔══██╗██║████╗  ██║██╔════╝     ██╔══██╗██╔══██╗██╔════╝                //
//                 ██║   ███████║█████╗      ██████╔╝██║   ██║██████╔╝██║██╔██╗ ██║██║  ███╗    ███████║██████╔╝█████╗                  //
//                 ██║   ██╔══██║██╔══╝      ██╔══██╗██║   ██║██╔══██╗██║██║╚██╗██║██║   ██║    ██╔══██║██╔═══╝ ██╔══╝                  //
//                 ██║   ██║  ██║███████╗    ██████╔╝╚██████╔╝██║  ██║██║██║ ╚████║╚██████╔╝    ██║  ██║██║     ███████╗                //
//                 ╚═╝   ╚═╝  ╚═╝╚══════╝    ╚═════╝  ╚═════╝ ╚═╝  ╚═╝╚═╝╚═╝  ╚═══╝ ╚═════╝     ╚═╝  ╚═╝╚═╝     ╚══════╝                //
//                              ██████╗██╗  ██╗██████╗  ██████╗ ███╗   ██╗██╗ ██████╗██╗     ███████╗███████╗                           //
//                             ██╔════╝██║  ██║██╔══██╗██╔═══██╗████╗  ██║██║██╔════╝██║     ██╔════╝██╔════╝                           //
//                             ██║     ███████║██████╔╝██║   ██║██╔██╗ ██║██║██║     ██║     █████╗  ███████╗                           //
//                             ██║     ██╔══██║██╔══██╗██║   ██║██║╚██╗██║██║██║     ██║     ██╔══╝  ╚════██║                           //
//                             ╚██████╗██║  ██║██║  ██║╚██████╔╝██║ ╚████║██║╚██████╗███████╗███████╗███████║                           //
//                              ╚═════╝╚═╝  ╚═╝╚═╝  ╚═╝ ╚═════╝ ╚═╝  ╚═══╝╚═╝ ╚═════╝╚══════╝╚══════╝╚══════╝                           //
//    ██╗██╗██╗██╗██╗██╗██╗██╗██╗██╗██╗██╗██╗██╗██╗██╗██╗██╗██╗██╗██╗██╗██╗██╗██╗██╗██╗██╗██╗██╗██╗██╗██╗██╗██╗██╗██╗██╗██╗██╗██╗██╗    //
//    ╚═╝╚═╝╚═╝╚═╝╚═╝╚═╝╚═╝╚═╝╚═╝╚═╝╚═╝╚═╝╚═╝╚═╝╚═╝╚═╝╚═╝╚═╝╚═╝╚═╝╚═╝╚═╝╚═╝╚═╝╚═╝╚═╝╚═╝╚═╝╚═╝╚═╝╚═╝╚═╝╚═╝╚═╝╚═╝╚═╝╚═╝╚═╝╚═╝╚═╝╚═╝╚═╝    //
//                                                 ████████╗██████╗  █████╗  ██████╗                                                    //
//                                                 ╚══██╔══╝██╔══██╗██╔══██╗██╔════╝                                                    //
//    █████╗█████╗█████╗█████╗█████╗█████╗█████╗█████╗██║   ██████╔╝███████║██║█████╗█████╗█████╗█████╗█████╗█████╗█████╗█████╗█████╗   //
//    ╚════╝╚════╝╚════╝╚════╝╚════╝╚════╝╚════╝╚════╝██║   ██╔══██╗██╔══██║██║╚════╝╚════╝╚════╝╚════╝╚════╝╚════╝╚════╝╚════╝╚════╝   //
//                                                    ██║   ██████╔╝██║  ██║╚██████╗                                                    //
//                                                    ╚═╝   ╚═════╝ ╚═╝  ╚═╝ ╚═════╝                                                    //
//                                                                                                                                      //
//                                                                                                                                      //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract TBAC is ERC1155Creator {
    constructor() ERC1155Creator() {}
}
  


import {expect} from "chai";
import {network} from "hardhat";

describe("MultiSigWallet", function (){
    let owner1 : any;
    let owner2 : any;
    let owner3 : any;
    let ethers : any;
    let networkHelpers : any;
    let MultiSigWallet: any;

    beforeEach(async function () {
        ({ethers, networkHelpers} = await network.create());
        [owner1, owner2, owner3] = await ethers.getSigners();
        MultiSigWallet = await ethers.deployContract("MultiSigWallet");
        await MultiSigWallet.waitForDeployment();
    });

})
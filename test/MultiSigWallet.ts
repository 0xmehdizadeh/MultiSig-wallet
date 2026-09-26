import {expect} from "chai";
import {network} from "hardhat";

describe("MultiSigWallet", function (){
    let owner1 : any;
    let owner2 : any;
    let owner3 : any;
    let user1 : any;
    let user2 : any;
    let ethers : any;
    let networkHelpers : any;
    let MultiSigWallet: any;

    beforeEach(async function () {
        ({ethers, networkHelpers} = await network.create());
        [owner1, owner2, owner3, user1, user2] = await ethers.getSigners();
        MultiSigWallet = await ethers.deployContract("MultiSigWallet");
        await MultiSigWallet.waitForDeployment();
    });

    it("Should allow owner to add owners", async function () {
        await MultiSigWallet.connect(owner1).addOwner(owner2.address);
        await MultiSigWallet.connect(owner1).addOwner(owner3.address);
        expect(await MultiSigWallet.isOwner(owner2.address)).to.be.true;
        expect(await MultiSigWallet.isOwner(owner3.address)).to.be.true;
        await expect(MultiSigWallet.connect(owner3).addOwner(owner2.address)).to.be.revertedWith("Address is already an owner");
        await expect(MultiSigWallet.connect(owner1).addOwner(ethers.ZeroAddress)).to.be.revertedWith("Invalid owner address");
        await expect(MultiSigWallet.connect(user1).addOwner(user2)).to.be.revertedWith("Only owners can call this function");
    });

})
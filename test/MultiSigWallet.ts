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
        await owner1.sendTransaction({
          to: await MultiSigWallet.getAddress(),
          value: ethers.parseEther("10.0"), // Enough for all tests
        });
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

   it("Should allow owner to remove owners", async function () {
    await MultiSigWallet.connect(owner1).addOwner(owner2.address);
    await MultiSigWallet.connect(owner1).addOwner(owner3.address);
    await MultiSigWallet.connect(owner1).changeThreshold(2);
    await MultiSigWallet.connect(owner1).removeOwner(owner2.address);
    expect(await MultiSigWallet.isOwner(owner2.address)).to.be.false;
    await expect(MultiSigWallet.connect(owner1).removeOwner(owner2.address)).to.be.revertedWith("Address is not an owner");
    await expect(MultiSigWallet.connect(owner1).removeOwner(owner1.address)).to.be.revertedWith("Owner cannot remove themselves");
    await expect(MultiSigWallet.connect(user1).removeOwner(owner3.address)).to.be.revertedWith("Only owners can call this function");
    await expect(
      MultiSigWallet.connect(owner1).removeOwner(owner3.address),
    ).to.be.revertedWith(
      "Threshold must be less than or equal to the number of remaining owners",
    );
   });

   it("Should allow owner to change threshold", async function(){
    await expect(
      MultiSigWallet.connect(owner1).changeThreshold(2),
    ).to.be.revertedWith("Invalid threshold");
    await MultiSigWallet.connect(owner1).addOwner(owner2.address);
    await MultiSigWallet.connect(owner1).addOwner(owner3.address);
    await MultiSigWallet.connect(owner2).changeThreshold(2);
    expect(await MultiSigWallet.threshold()).to.equal(2);
   });

   it("Should allow owner to submit transactions", async function(){
    await MultiSigWallet.connect(owner1).submitTransaction(user1.address, 1, "0x");
    await expect(MultiSigWallet.connect(user1).submitTransaction(user2.address, 1, "0x")).to.be.revertedWith("Only owners can call this function");
    expect(await MultiSigWallet.transactionCount()).to.equal(1);
    await expect(
      MultiSigWallet.connect(owner1).submitTransaction(
        ethers.ZeroAddress,
        1,
        "0x",
      ),
    ).to.be.revertedWith("Invalid recipient address");

    const tx = await MultiSigWallet.transactions(0);
    expect(tx.to).to.equal(user1.address);
    expect(tx.value).to.equal(1);
    expect(tx.approvalCount).to.equal(0);
    expect(tx.executed).to.be.false;
   });

   it("Should allow owner to approve transactions", async function(){
    await MultiSigWallet.connect(owner1).addOwner(owner2.address);
    await MultiSigWallet.connect(owner1).addOwner(owner3.address);
    await MultiSigWallet.connect(owner1).submitTransaction(user1.address, 1, "0x");
    await MultiSigWallet.connect(owner1).changeThreshold(2);
    await MultiSigWallet.connect(owner2).approveTransaction(0);
    await MultiSigWallet.connect(owner3).approveTransaction(0);
    await expect(
      MultiSigWallet.connect(owner1).approveTransaction(1),
    ).to.be.revertedWith("Transaction does not exist");
    await expect(
      MultiSigWallet.connect(owner3).approveTransaction(0),
    ).to.be.revertedWith("Transaction already approved by this owner");
    const tx = await MultiSigWallet.transactions(0);
    expect(tx.approvalCount).to.equal(2);
   });

   it("Should allow owners to execute transactions", async function(){
    await MultiSigWallet.connect(owner1).addOwner(owner2.address);
    await MultiSigWallet.connect(owner1).addOwner(owner3.address);
    await MultiSigWallet.connect(owner1).submitTransaction(
      user1.address,
      ethers.parseEther("0.1"),
      "0x",
    );
    await MultiSigWallet.connect(owner1).changeThreshold(2);
    await MultiSigWallet.connect(owner2).approveTransaction(0);

    await expect(
      MultiSigWallet.connect(owner2).executeTransaction(0),
    ).to.be.revertedWith("Not enough approvals");

    await MultiSigWallet.connect(owner3).approveTransaction(0);
    await MultiSigWallet.connect(owner1).executeTransaction(0);

    const tx = await MultiSigWallet.transactions(0);
    expect(tx.executed).to.be.true;
   });
})
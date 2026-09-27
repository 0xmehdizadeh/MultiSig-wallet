import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";

export default buildModule("MultiSigWalletModule", (m) => {
  const multiSigWallet = m.contract("MultiSigWallet");
  return { multiSigWallet };
});

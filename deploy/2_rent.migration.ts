import { Deployer, Reporter } from "@solarity/hardhat-migrate";

import { Rent__factory } from "@ethers-v6";

export = async (deployer: Deployer) => {
  const rent = await deployer.deploy(Rent__factory);
  
  Reporter.reportContracts(["Rent", await rent.getAddress()]);
};

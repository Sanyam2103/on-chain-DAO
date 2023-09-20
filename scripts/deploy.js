
const hre = require("hardhat")

async function sleep(seconds) {
  return new Promise((resolve) => setTimeout(resolve, seconds))
}

async function main() {
  /*const nftContract = await hre.ethers.deployContract("CryptoDevsNFT")
  await nftContract.waitForDeployment()
  console.log("CryptoDevsNFT deployed to:", nftContract.target)

  const fakeNftMarketplaceContract = await hre.ethers.deployContract("FakeNFTMarketplace")
  await fakeNftMarketplaceContract.waitForDeployment()
  console.log("FakeNFTMarketplace deployed to:", fakeNftMarketplaceContract.target)

  const amount = hre.ethers.parseEther("0.09")

  const daoContract = await hre.ethers.deployContract(
    "CryptoDevsDAO",
    [fakeNftMarketplaceContract.target, nftContract.target],
    { value: amount }
  )
  await daoContract.waitForDeployment()
  console.log("CryptoDevsDAO deployed to:", daoContract.target)

  await sleep(30000)
*/
  await hre.run("verify:verify", {
    address: "0x545ecf370a8850dc8347b072c17b4464f01f8ca1", //nftContract.target,
    constructorArguments: [],
  })

  // Verify the Fake Marketplace Contract
  await hre.run("verify:verify", {
    address: "0x38316c51c11f2e27893bf847133a99ec3433e1d5", //fakeNftMarketplaceContract.target,
    constructorArguments: [],
  })

  await hre.run("verify:verify", {
    address: "0x2e24df8f0765fd325172e930f7e7760fc7d19459", //daoContract.target,
    constructorArguments: [
      "0x38316c51c11f2e27893bf847133a99ec3433e1d5",
      "0x545ecf370a8850dc8347b072c17b4464f01f8ca1",
    ], //[fakeNftMarketplaceContract.target, nftContract.target],
  })
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error)
  process.exitCode = 1
})

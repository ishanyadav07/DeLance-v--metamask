import hre from 'hardhat'

async function main() {
  const EscrowMarketplace = await hre.ethers.getContractFactory('EscrowMarketplace')
  const escrowMarketplace = await EscrowMarketplace.deploy()

  await escrowMarketplace.waitForDeployment()

  console.log('EscrowMarketplace deployed to:', await escrowMarketplace.getAddress())
}

main().catch((error) => {
  console.error(error)
  process.exitCode = 1
})

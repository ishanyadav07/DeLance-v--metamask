import { expect } from 'chai'
import { ethers } from 'hardhat'

describe('EscrowMarketplace', function () {
  it('creates a job, funds a milestone, and approves it', async function () {
    const [client, freelancer] = await ethers.getSigners()

    const EscrowMarketplace = await ethers.getContractFactory('EscrowMarketplace')
    const escrowMarketplace = await EscrowMarketplace.deploy()
    await escrowMarketplace.waitForDeployment()

    const tx = await escrowMarketplace.connect(client).createJob(freelancer.address)
    const receipt = await tx.wait()
    const jobId = receipt.logs[0].args.jobId

    await escrowMarketplace
      .connect(client)
      .addMilestone(jobId, 'Initial delivery', ethers.parseEther('0.5'))

    await escrowMarketplace
      .connect(client)
      .fundMilestone(jobId, 0, { value: ethers.parseEther('0.5') })

    await escrowMarketplace.connect(freelancer).submitMilestone(jobId, 0)

    await expect(() =>
      escrowMarketplace.connect(client).approveMilestone(jobId, 0)
    ).to.changeEtherBalances(
      [freelancer, escrowMarketplace],
      [ethers.parseEther('0.5'), ethers.parseEther('-0.5')]
    )

    expect(await escrowMarketplace.freelancerReputation(freelancer.address)).to.equal(1)
  })

  it('opens a dispute and resolves it via DAO vote', async function () {
    const [owner, client, freelancer, daoVoter, daoVoterTwo] = await ethers.getSigners()

    const EscrowMarketplace = await ethers.getContractFactory('EscrowMarketplace')
    const escrowMarketplace = await EscrowMarketplace.connect(owner).deploy()
    await escrowMarketplace.waitForDeployment()

    await escrowMarketplace.connect(owner).setDaoVoter(daoVoter.address, true)
    await escrowMarketplace.connect(owner).setDaoVoter(daoVoterTwo.address, true)
    await escrowMarketplace.connect(owner).setDisputeQuorum(2)

    const tx = await escrowMarketplace.connect(client).createJob(freelancer.address)
    const receipt = await tx.wait()
    const jobId = receipt.logs[0].args.jobId

    await escrowMarketplace
      .connect(client)
      .addMilestone(jobId, 'Draft delivery', ethers.parseEther('0.25'))

    await escrowMarketplace
      .connect(client)
      .fundMilestone(jobId, 0, { value: ethers.parseEther('0.25') })

    await escrowMarketplace.connect(freelancer).submitMilestone(jobId, 0)

    await escrowMarketplace
      .connect(client)
      .openDispute(jobId, 'Quality issue', 3600)

    await escrowMarketplace.connect(daoVoter).voteDispute(jobId, true)
    await escrowMarketplace.connect(daoVoterTwo).voteDispute(jobId, true)

    await ethers.provider.send('evm_increaseTime', [3601])
    await ethers.provider.send('evm_mine')

    await expect(() =>
      escrowMarketplace.connect(daoVoter).resolveDispute(jobId)
    ).to.changeEtherBalances(
      [freelancer, escrowMarketplace],
      [ethers.parseEther('0.25'), ethers.parseEther('-0.25')]
    )

    expect(await escrowMarketplace.freelancerReputation(freelancer.address)).to.equal(1)
  })
})

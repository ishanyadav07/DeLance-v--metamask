# Product requirements and permissions

## Target chain and wallets
- Default testnet: Base Sepolia
- Wallets: MetaMask, WalletConnect, Coinbase Wallet

## Core roles
- Client: posts jobs, funds escrow, approves milestones, opens disputes
- Freelancer: accepts jobs, submits milestones, opens disputes
- DAO voter: votes on disputes and resolves outcomes
- Owner: manages DAO voter allowlist and quorum settings

## Job lifecycle
1. Client creates job and adds milestones
2. Client funds each milestone
3. Freelancer submits milestone work
4. Client approves milestone or opens dispute
5. DAO votes if disputed, payout is resolved

## Escrow rules
- Funds locked per milestone
- Approved milestones release funds to freelancer
- Dispute resolution pays remaining funded milestones to either party
- Reputation updates on milestone approval and dispute outcome

## Permissions summary
- Only client can fund and approve milestones
- Only freelancer can submit milestones
- Only client or freelancer can open disputes
- Only DAO voters can vote or resolve disputes
- Only owner can manage DAO voters and quorum

## Implementation status

- [x] Escrow rules implemented in `contracts/contracts/EscrowMarketplace.sol`
- [x] Role/permission restrictions implemented in contract modifiers
- [x] Milestone lifecycle actions implemented (fund, submit, approve)
- [x] Dispute open/vote/resolve logic implemented
- [x] Reputation updates implemented on approval and dispute outcome
- [ ] Wallet connection integration in frontend
- [ ] End-to-end frontend to contract wiring
- [ ] Backend profile/search metadata APIs

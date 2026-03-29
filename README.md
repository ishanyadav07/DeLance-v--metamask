# Decentralized Freelance Marketplace

Web3 freelance platform with escrow-based milestone payments, dispute resolution, and reputation tracking.

## Workspace overview

- Frontend (Vite + React + TypeScript): root project (`src`, `package.json`)
- Backend (Express): `backend/`
- Smart contracts (Hardhat): `contracts/`
- Project docs: `docs/`

## Run frontend

1. Install dependencies:
   `npm install`
2. Start dev server:
   `npm run dev`
3. Build:
   `npm run build`

## Run backend

1. Go to backend:
   `cd backend`
2. Install dependencies:
   `npm install`
3. Create env file:
   `copy .env.example .env`
4. Start backend:
   `npm run dev`

## Run contracts

1. Go to contracts:
   `cd contracts`
2. Install dependencies:
   `npm install`
3. Run tests:
   `npx hardhat test`
4. Deploy with script (configure network first):
   `npx hardhat run scripts/deploy.js`

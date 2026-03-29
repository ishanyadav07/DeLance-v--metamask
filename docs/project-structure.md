# Folder Structure

## Current workspace structure (implemented)

- root frontend
  - `src/` : React app source
    - `components/` : shared UI and layout
    - `pages/` : route-level screens
    - `types/` : frontend types
    - `utils/` : frontend helpers
  - `package.json` : frontend scripts/dependencies
  - `vite.config.ts` and `tsconfig.json` : frontend tooling
- `backend/`
  - `src/`
    - `config/`
    - `controllers/`
    - `middleware/`
    - `models/`
    - `routes/` (health route exists)
    - `services/`
    - `utils/`
  - `package.json` : backend scripts/dependencies
- `contracts/`
  - `contracts/EscrowMarketplace.sol` : escrow marketplace contract
  - `scripts/deploy.js` : deployment script
  - `test/EscrowMarketplace.test.js` : contract tests
  - `hardhat.config.js` and `package.json`
- `docs/`
  - `roadmap.md`
  - `requirements.md`
  - `future-needs.md`
  - `project-structure.md`
  - `freelancer-readme.md` (archived notes)

## Status

- [x] Duplicate nested project folder removed
- [x] Backend moved to root-level `backend/`
- [x] Contracts moved to root-level `contracts/`
- [x] Core docs consolidated under root-level `docs/`
- [ ] Shared cross-app package (`shared/`) not yet recreated at root

## Why this structure works

- Frontend, backend, and contracts are clearly separated
- Root-level apps are easier to run and maintain
- Future scaling is straightforward for shared types/services

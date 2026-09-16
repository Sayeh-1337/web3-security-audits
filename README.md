# web3-security-audits

Lab workspace for web3 security research: post-mortem audits and CTF writeups.

## Layout

```
web3-security-audits/
  truebit-post-mortem-security-audit/   Truebit exploit post-mortem
  web3-ctf-challenges/                  One folder per CTF challenge
    01-ethernaut-fallback/
```

## CTF challenges

Each challenge lives in its own folder under `web3-ctf-challenges/`. Do not mix exploits or notes across challenges.

Current: [01 Ethernaut Fallback](web3-ctf-challenges/01-ethernaut-fallback/).

To run the Fallback Foundry tests:

```bash
cd web3-ctf-challenges/01-ethernaut-fallback
forge install foundry-rs/forge-std
forge test --match-test testExploit -vv
```

## Audits

- [Truebit post-mortem](truebit-post-mortem-security-audit/) — arithmetic overflow, reserve drain, defensive lessons

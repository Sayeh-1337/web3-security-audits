# Truebit Post-Mortem Security Audit

This repository contains a comprehensive post-mortem security analysis of a real-world exploit affecting the Truebit protocol smart contracts deployed on Ethereum.

The purpose of this repository is **educational and defensive**: to document how the exploit occurred, why existing protections were insufficient, and what lessons can be applied to prevent similar vulnerabilities in smart contract systems.

---

## 📋 Overview

This audit documents a deterministic economic exploit that resulted in the draining of ETH reserves from a Truebit smart contract.
The vulnerability was **purely arithmetic** in nature and arose from **overflow-prone calculations combined with unchecked arithmetic operations**, despite partial use of SafeMath.

The repository includes:

* Decompiled bytecode of the compromised contract
* Decompiled bytecode of the attacker contract
* A detailed technical audit
* Supporting methodology and appendix documentation

---

## 📂 Repository Contents

### Smart Contracts

* **`compromised_contract.txt`**
  Decompiled bytecode of the Truebit contract that was exploited

  * Contract Address: `0xc186e6f0163e21be057e95aa135edd52508d14d3`
  * Implements TRU token pricing, reserve management, and role-based access control
  * Key functions:

    * `buyTRU()`
    * `sellTRU()`
    * `getPurchasePrice()`
    * `getRetirePrice()`
    * `withdrawETH()`

* **`attacker_contract.txt`**
  Decompiled bytecode of the malicious contract used in the exploit

  * Contract Address: `0x1De399967B206e446B4E9AeEb3Cb0A0991bF11b8`
  * Automates repeated interactions with the compromised contract to extract ETH

---

### Documentation

* **`truebit_security_audit.pdf`**
  Main audit report detailing findings and root-cause analysis

* **`truebit_security_audit_appendix.pdf`**
  Bytecode-level technical appendix (corrected)

* **`truebit_methodology_appendix.pdf`**
  Investigation methodology and tooling used during analysis

---

## 🔍 Attack Overview

### Summary

The exploit was enabled by a **multi-stage arithmetic vulnerability chain** in the pricing logic of the Truebit contract.

### Primary Vulnerability

> **Overflow-prone multiplication + unchecked EVM addition + late SafeMath protection**

More precisely:

* Intermediate multiplication operations produced **wrapped values** due to integer overflow (Solidity <0.8 behavior).
* These wrapped values were later **recombined using a raw EVM `ADD` opcode** without overflow protection.
* SafeMath checks were applied **only at the final division step**, too late to prevent corrupted values from influencing pricing.

This sequence allowed **corrupted pricing values to pass validation**, enabling deterministic reserve draining.

---

## 🧠 Root Cause Analysis

### Why SafeMath Did Not Prevent the Exploit

The contract uses SafeMath **partially**, but arithmetic protection was applied **inconsistently**.

Key issue:

> SafeMath division was applied to values that were **already corrupted by prior unchecked arithmetic operations**.

SafeMath can guarantee the correctness of the division itself, but it **cannot repair invalid inputs**.

---

## ⚙️ Exploit Mechanics

### Vulnerable Calculation Chain

```
getPurchasePrice(amount)
├── TRU_TOKEN.totalSupply()
├── func_18EF(supply, supply)
│   └── Overflow-prone multiplication (wrapped intermediate values)
├── func_150D(storage[0x98], var6)
├── func_151B(supply, var4)
└── func_154F(amount, supply, var3)
    └── Unchecked EVM ADD combines corrupted values
        ↓
    SafeMath division applied after corruption
```

---

### Critical Arithmetic Properties

#### 1. Overflow-Prone Multiplication (`func_18EF`)

* Performs multiplication before validation
* Wrapped intermediate values can propagate downstream
* Validation occurs **after** overflow has already happened

#### 2. Unchecked EVM ADD (`func_154F`)

* Uses raw EVM `ADD` opcode
* No overflow protection
* Combines multiple already-corrupted values
* This is the **primary exploit sink**

#### 3. Late SafeMath Division (`func_1C64`)

* Division itself is safe
* Inputs are already compromised
* Creates a false sense of security

---

## 🔬 Pseudocode Representation (Conceptual)

```solidity
function getPurchasePrice(uint256 amount) returns (uint256) {
    uint256 supply = TRU_TOKEN.totalSupply();

    // Stage 1: Overflow-prone multiplication
    uint256 v1 = supply * supply;  // wraps on overflow (Solidity <0.8)

    uint256 v2 = v1 * parameter;   // propagates wrapped value
    uint256 v3 = complexPricingLogic(supply, v2);

    // Stage 2: Unchecked ADD (EVM ADD)
    uint256 corrupted = v3 + amount; // no overflow protection

    // Stage 3: Safe division applied too late
    return SafeMath.div(corrupted, divisor);
}
```

**Important:**
The vulnerability is **not** that SafeMath is incorrect — it is that **SafeMath is applied after unchecked arithmetic has already corrupted the calculation**.

---

## 🔁 Why Deterministic Reserve Draining Was Possible

* Overflow thresholds were predictable
* Arithmetic corruption was reproducible
* No invariant enforced reserve preservation
* Attacker could repeatedly execute the same profitable cycle
* No randomness or oracle dependency

The attacker simply repeated the exploit until the ETH reserve reached zero.

---

## 🛠️ Technical Details

### Technologies Involved

* **Blockchain**: Ethereum Mainnet
* **Language**: Solidity (contracts are provided as decompiled bytecode)
* **Solidity Version**: Pre-0.8 (integer overflow wrapping behavior)
* **Standards**: ERC-20 token standard, AccessControl pattern
* **Tools Used**: Etherscan, Online Solidity Decompiler

---

### Contract Interactions

The attack exploited a multi-stage arithmetic vulnerability through specific function call chains:

* **Pricing Mechanisms**: Arithmetic operations on reserves and token supply in `getPurchasePrice()`
* **Reserve Calculations**: Addition/multiplication operations that could overflow
* **Token Supply Tracking**: Supply calculations vulnerable to wraparound at high token counts
* **Price Computation Functions**: Both `getPurchasePrice()` and `getRetirePrice()` performed unsafe arithmetic, though `getPurchasePrice()` was the primary attack vector

The attacker's contract manipulated token supply and purchase amounts to trigger overflow conditions at precise thresholds, resulting in corrupted pricing that allowed systematic value extraction.

---

### Vulnerable Code Path: `getPurchasePrice()` Function Chain

The overflow vulnerability was specifically exploited through the `getPurchasePrice()` function (`func_1446`) and its complete call chain:

#### Function: `func_1446` (getPurchasePrice)

**Price Calculation Function** that contained the vulnerable code path:

* **Function Signature**: `getPurchasePrice(uint256 amount) returns (uint256)`
* **Internal Name**: `func_1446`
* **Bytecode Start**: `0x1446`
* **Decompiled Lines**: 1177-1222
* **Entry Point**: Public function accessible via `0xc59d5633` (function selector)

#### Complete Function Call Chain

```
getPurchasePrice(uint256 amount) returns (uint256)
│
├── TRU_TOKEN.totalSupply()
│   └── Retrieves current token supply (critical input to vulnerability)
│
├── func_18EF(supply, supply)
│   └── ⚠️ VULNERABLE #1: Overflow-prone multiplication
│       • Performs: supply × supply (squaring operation)
│       • No overflow protection
│       • Bytecode location: Called at 0x150C
│       • Opcode sequence at call site:
│         150C 60 PUSH1 0x18ef    // Push func_18EF address
│         150E 56 JUMP            // Jump to multiply function
│       • Wraps on overflow when supply exceeds ~2^128
│
├── func_150D(storage[0x98], var6)
│   └── Multiplies wrapped result by stored parameter
│       • Uses corrupted value from func_18EF
│       • Propagates overflow corruption downstream
│
├── func_151B(supply, var4)
│   └── Additional pricing calculations
│       • Combines supply with already-corrupted intermediate values
│       • No validation of input integrity
│
└── func_154F(amount, supply, var3)
    └── ⚠️ VULNERABLE #2: Unchecked EVM ADD (PRIMARY EXPLOIT SINK)
        • Uses raw EVM ADD opcode (0x01)
        • No overflow protection
        • Combines multiple corrupted values:
          - var3 (contains wrapped values from earlier stages)
          - amount (user-controlled input)
          - supply (current token supply)
        • Critical: This is where corrupted values are definitively incorporated
        • Result: corrupted_price (already compromised)
        │
        └── func_1C64(corrupted_price, divisor)
            └── ⚠️ VULNERABLE #3: SafeMath Division Applied Too Late
                • SafeMath division function
                • Division itself is mathematically safe
                • Inputs are already corrupted from previous stages
                • Creates false validation: "passed SafeMath check"
                • Returns: manipulated price that drains reserves
```

#### Critical Vulnerability Locations

**1. Multiplication Overflow Point (func_18EF)**

* **Bytecode Address**: `0x150C` (call site)
* **Opcode Sequence**:
  ```
  150C 60 PUSH1 0x18ef    // Push func_18EF function address
  150E 56 JUMP            // Unconditional jump to multiplication function
  ```
* **Vulnerability**: The multiplication `supply²` overflows when token supply exceeds `sqrt(2^256 - 1) ≈ 2^128`. The wrapped result propagates through all subsequent calculations.

**2. Unchecked ADD Operation (func_154F)**

* **Function**: `func_154F`
* **Operation**: Raw EVM `ADD` opcode (0x01)
* **Vulnerability**: Performs addition without checking for overflow conditions
* **Impact**: This is the **primary exploit sink** where corrupted intermediate values are definitively combined with user-controlled inputs, producing the final corrupted pricing value.

**3. Late SafeMath Division (func_1C64)**

* **Function**: `func_1C64` (SafeMath-like division)
* **Protection**: Division operation itself is safe
* **Problem**: Applied to values already corrupted by prior unchecked operations
* **Result**: Corrupted pricing passes validation, enabling reserve draining

#### Bytecode-Level Pseudo-code

```solidity
function func_1446(uint256 amount) returns (uint256) {
    // Line 1177-1203: Get total supply from TRU token
    uint256 supply = TRU_TOKEN.totalSupply();
    
    // Line 1205-1216: Calculate price components
    // CRITICAL: This chain includes multiple vulnerable operations
    
    // Stage 1: VULNERABLE MULTIPLICATION (func_18EF)
    // Bytecode: 0x150C-0x150E
    // ⚠️ Integer overflow - no checks, wraps on overflow
    var6 = func_18EF(supply, supply);      
    // Result: supply² → OVERFLOWS/WRAPS when supply > 2^128
    
    // Stage 2: Propagate corrupted value
    var4 = func_150D(storage[0x98], var6); 
    // Uses corrupted var6, further corruption propagates
    
    var3 = func_151B(supply, var4);        
    // Additional calculations with corrupted intermediate values
    
    // Stage 3: VULNERABLE ADDITION (func_154F)
    // ⚠️ Unchecked EVM ADD opcode - PRIMARY EXPLOIT SINK
    corrupted_price = func_154F(amount, supply, var3);  
    // Inside func_154F: 
    //   Uses raw EVM ADD (0x01) with no overflow protection
    //   Combines: corrupted var3 + amount + supply calculations
    //   Result: Final corrupted pricing value
    
    // Stage 4: SafeMath Division (TOO LATE!)
    // ✅ Division operation itself is safe
    // ❌ But inputs are already corrupted from stages 1-3
    // Corrupted pricing values pass validation
    return func_1C64(corrupted_price, divisor);
    // SafeMath.div() validates corrupted input as "safe"
}
```

#### Why This Attack Sequence Works

The vulnerability chain exploits the **ordering and partial protection** of arithmetic operations:

1. **Early overflow** in multiplication creates corrupted intermediate values
2. **Unchecked addition** in `func_154F` allows corrupted values to compound and become definitively incorporated into pricing
3. **Late SafeMath** division validates the corrupted result, creating a false sense of security
4. **Deterministic exploitation** because overflow thresholds are predictable and reproducible

The attacker manipulates token supply and purchase amounts to trigger overflow at the multiplication stage, allowing the corruption to flow through unchecked addition, ultimately producing pricing that passes SafeMath validation but drains reserves.

---

## 🔐 Security Lessons

### Primary Lesson: Arithmetic Safety Is All-or-Nothing

* Protect **every arithmetic operation**, not just the final step
* Overflow-prone operations early in a calculation chain cannot be "fixed later"
* Unchecked EVM `ADD` or `MUL` opcodes are sufficient to undermine SafeMath elsewhere

### Additional Lessons

* Solidity <0.8 contracts require extreme caution
* Economic invariants must be enforced explicitly
* Bonding-curve and pricing logic deserves extra scrutiny
* Formal verification should be applied to value-critical code paths

---

## 🎓 Educational Purpose

This repository serves as:

* A real-world **case study** in smart contract failures
* A **learning resource** for auditors and developers
* A **reference example** of partial SafeMath misuse
* A **post-mortem record** for responsible security research

---

## 🔗 Contract Links

* **Compromised Contract**
  [https://etherscan.io/address/0xc186e6f0163e21be057e95aa135edd52508d14d3](https://etherscan.io/address/0xc186e6f0163e21be057e95aa135edd52508d14d3)

* **Attacker Contract**
  [https://etherscan.io/address/0x1De399967B206e446B4E9AeEb3Cb0A0991bF11b8](https://etherscan.io/address/0x1De399967B206e446B4E9AeEb3Cb0A0991bF11b8)

---

## ⚠️ Disclaimer

This repository is provided **strictly for educational and defensive security research**.

Do **not** use this information for malicious purposes.
Always follow responsible disclosure practices.

---

## 📄 License

Provided as-is for research and educational use.
Smart contract bytecode is publicly available on the Ethereum blockchain.

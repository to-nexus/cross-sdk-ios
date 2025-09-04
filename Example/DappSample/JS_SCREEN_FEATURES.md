### Cross SDK Vanilla 데모 화면 기능 정의

이 문서는 `examples/sdk-vanilla/src/main.js` 기반으로 데모 화면의 기능과 각 기능에서 사용하는 체인별 컨트랙트 요청 정보를 정리합니다.

---

## 개요

- **SDK 초기화**: `initCrossSdkWithParams({ projectId, redirectUrl, metadata, themeMode })`
- **지갑 제어**: `useAppKitWallet()`로 연결/해제
- **주요 컨트롤러**: `AccountController`, `ConnectionController`, `SendController`, `ConstantsUtil`
- **대상 체인**: Cross(Mainnet/Testnet), BSC(Mainnet/Testnet), Kaia(Mainnet/Testnet), Ethereum(Mainnet/Sepolia)

---

## 네트워크 및 컨트랙트 매핑

아래는 소스의 `contractData` 기준 체인별 기본 컨트랙트 주소입니다.

|  체인 ID | 네트워크         | 코인  | ERC-20 주소                                | ERC-721 주소                               |
| -------: | ---------------- | ----- | ------------------------------------------ | ------------------------------------------ |
|   612044 | Cross Testnet    | CROSS | 0xe934057Ac314cD9bA9BC17AE2378959fd39Aa2E3 | 0xaD31a95fE6bAc89Bc4Cf84dEfb23ebBCA080c013 |
|   612055 | Cross Mainnet    | CROSS | 0xe9013a5231BEB721f4F801F2d07516b8ca19d953 |                                            |
|       97 | BSC Testnet      | BNB   |                                            |                                            |
|       56 | BSC Mainnet      | BNB   |                                            |                                            |
|     1001 | Kaia Testnet     | KAIA  | 0xd4846dddf83278d10b92bf6c169c5951d6f5abb8 |                                            |
|     8217 | Kaia Mainnet     | KAIA  |                                            |                                            |
|        1 | Ethereum Mainnet | ETH   |                                            |                                            |
| 11155111 | Ethereum Sepolia | ETH   |                                            |                                            |

- **CAIP 컨트랙트 식별자(ERC-20 전송 시 사용)**: `${networkState.caipNetworkId}:${ERC20_ADDRESS}`
- **기본 소수점**: `decimals = 18`

---

## 기능 정의 및 체인별 요청 컨트랙트

### 1) 지갑 연결/해제

- **UI**: `#connect-wallet`
- **동작**: 연결됨이면 `disconnect()`, 미연결이면 `connect('cross_wallet')`
- **컨트랙트**: 없음

### 2) 네트워크 전환

- **UI**: `#switch-network` → 네트워크 모달에서 선택 시 `crossSdk.switchNetwork(network)`
- **컨트랙트**: 없음 (네트워크/프로바이더 수준)

### 3) 메시지 서명 (Personal Sign)

- **트리거**: `#sign-message`
- **API**: `ConnectionController.signMessage({ message, customData })`
- **컨트랙트**: 없음

### 4) EIP-712 Typed Data V4 서명

- **트리거**: `#sign-typed-data-v4`
- **API 흐름**:
  - 서버에서 typedData 수신(두 번째 params 요소)
  - `ConnectionController.signTypedDataV4(typedData, { metadata })`
- **컨트랙트**: 없음 (메시지 서명)

### 5) Provider 임의 요청

- **트리거**: `#provider-request`
- **예시**: `eip155Provider.request({ method: 'eth_chainId' })`
- **컨트랙트**: 없음

### 6) 네이티브 코인 전송

- **트리거**: `#send-native`, `#send-native-dynamic`
- **API**: `SendController.sendNativeToken({ receiverAddress, sendTokenAmount, decimals, type })`
- **금액 정책**:
  - 체인ID 1(Mainnet), 11155111(Sepolia): `0.0001 ETH`
  - 그 외: `1 {체인 코인}` (예: CROSS)
- **컨트랙트**: 없음 (네이티브 송금)

### 7) ERC-20 토큰 전송

- **트리거**: `#send-erc20`, `#send-erc20-dynamic`
- **API**: `SendController.sendERC20Token({ receiverAddress, contractAddress: CAIP, sendTokenAmount, decimals, type })`
- **전송 대상 컨트랙트(체인별)**

|                   체인 ID | 네트워크      | ERC-20 주소                                | 비고        |
| ------------------------: | ------------- | ------------------------------------------ | ----------- |
|                    612044 | Cross Testnet | 0xe934057Ac314cD9bA9BC17AE2378959fd39Aa2E3 | 사용 가능   |
|                    612055 | Cross Mainnet | 0xe9013a5231BEB721f4F801F2d07516b8ca19d953 | 사용 가능   |
|                      1001 | Kaia Testnet  | 0xd4846dddf83278d10b92bf6c169c5951d6f5abb8 | 사용 가능   |
| 97, 56, 8217, 1, 11155111 | -             | (설정 없음)                                | 기능 비활성 |

- **CAIP 주소 예**: `612044:0xe934057Ac314cD9bA9BC17AE2378959fd39Aa2E3`

### 8) 커스텀 트랜잭션(컨트랙트 호출)

- **트리거**: `#send-transaction`, `#send-transaction-dynamic`
- **API**: `ConnectionController.writeContract({ fromAddress, contractAddress, args, method, abi, chainNamespace, type })`
- **디폴트 데모 메서드**: `mintTo(address, uint256)` (ERC-721)
- **호출 대상 컨트랙트(체인별)**

| 체인 ID | 네트워크      | ERC-721 주소                               | 메서드                  |
| ------: | ------------- | ------------------------------------------ | ----------------------- |
|  612044 | Cross Testnet | 0xaD31a95fE6bAc89Bc4Cf84dEfb23ebBCA080c013 | mintTo(address,uint256) |
|   그 외 | -             | (설정 없음)                                | -                       |

### 9) 잔액 조회

- **네이티브**: `accountState.balance` 사용 (컨트랙트 없음)
- **ERC-20**: `readContract({ contractAddress: ERC20_ADDRESS, method: 'balanceOf', abi, args: [address] })`
  - 주소/가용 체인: 위 [ERC-20 전송 표]와 동일
- **ERC-721**: `readContract({ contractAddress: ERC721_ADDRESS, method: 'balanceOf', abi, args: [address] })`
  - 주소/가용 체인: 위 [커스텀 트랜잭션 표]와 동일

---

## UI 구성 요소 및 이벤트 바인딩

- **지갑**: `#connect-wallet`
- **테마**: `#toggle-theme` → `crossSdk.setThemeMode()`
- **네트워크 전환**: `#switch-network` → 모달에서 선택 시 적용
- **서명**: `#sign-message`, `#sign-typed-data-v4`
- **프로바이더 요청**: `#provider-request`
- **전송**: `#send-native`, `#send-native-dynamic`, `#send-erc20`, `#send-erc20-dynamic`
- **컨트랙트 호출**: `#send-transaction`, `#send-transaction-dynamic`
- **잔액**: `#get-balance-native`, `#get-balance-erc20`, `#get-balance-nft`

---

## 참고 사항

- **LEGACY/DYNAMIC 수수료 타입**: `ConstantsUtil.TRANSACTION_TYPE.LEGACY | DYNAMIC`
- **동적 수수료 예시(선택)**: `gas`, `maxFee`, `maxPriorityFee`
- **주소 변경 시 토큰 잔액 자동 갱신**: `AccountController.fetchTokenBalance()` 호출

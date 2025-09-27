# KipuBank

**KipuBank** — Contrato inteligente educativo en Solidity para gestionar bóvedas personales en ETH con límite global y límite por retiro.

## Características principales

- Depósitos de ETH en bóvedas personales (`saldos` mapping).  
- Límite global de ETH en el banco (`topeBanco`) establecido al desplegar el contrato.  
- Límite máximo por retiro (`topeRetiro`) establecido al desplegar el contrato.  
- Eventos:  
  - `Deposito(address usuario, uint256 monto)`  
  - `Retiro(address usuario, uint256 monto)`  
- Errores personalizados para revertir con información detallada:  
  - `DepositoCero()`  
  - `TopeBancoSuperado(uint256 montoIntentado, uint256 espacioDisponible)`  
  - `TopeRetiroSuperado(uint256 montoIntentado, uint256 limiteTx)`  
  - `SaldoInsuficiente(uint256 saldo, uint256 solicitado)`  
  - `TransferenciaFallida()`  
  - `LlamadaReentrante()`  
- Contadores de operaciones: `cantidadDepositos` y `cantidadRetiros`.  
- Patrón *checks-effects-interactions* y protección contra reentrancia (`sinReentrancia` modifier).  
- Funciones:  
  - `depositar()` → permite depositar ETH.  
  - `retirar(uint256 monto)` → permite retirar ETH respetando el límite por transacción.  
  - `verSaldo(address usuario)` → devuelve el saldo de un usuario.  
  - `_aumentarSaldo(address usuario, uint256 monto)` → función interna para actualizar saldos.  
- Receive y fallback redirigen automáticamente a `depositar()`.

## Uso

1. Deployar el contrato especificando `topeBanco` y `topeRetiro`.  
2. Llamar a `depositar()` enviando ETH al contrato.  
3. Llamar a `retirar(uint256 monto)` para retirar ETH, respetando los límites.  
4. Consultar el saldo de cualquier usuario con `verSaldo(address usuario)`.

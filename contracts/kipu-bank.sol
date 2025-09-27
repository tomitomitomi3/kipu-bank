// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title KipuBank - Boveda de ETH con limite global y limite por retiro
/// @notice Permite a cada usuario guardar y retirar ETH con reglas de seguridad
contract KipuBank {

    error DepositoCero();
    error TopeBancoSuperado(uint256 montoIntentado, uint256 espacioDisponible);
    error TopeRetiroSuperado(uint256 montoIntentado, uint256 limiteTx);
    error SaldoInsuficiente(uint256 saldo, uint256 solicitado);
    error TransferenciaFallida();
    error LlamadaReentrante();

    address public immutable dueno;          // creador del contrato
    uint256 public immutable topeBanco;      // limite global de ETH en el banco
    uint256 public immutable topeRetiro;     // limite maximo por retiro
    uint256 public totalGuardado;            // ETH total en el contrato
    mapping(address => uint256) private saldos; // saldo individual de cada usuario
    uint256 public cantidadDepositos;
    uint256 public cantidadRetiros;

    event Deposito(address usuario, uint256 monto);
    event Retiro(address usuario, uint256 monto);

    //REENTRANCIA SIMPLE
    uint8 private desbloqueado = 1;
    modifier sinReentrancia() {
        if (desbloqueado == 0) revert LlamadaReentrante();
        desbloqueado = 0;
        _;
        desbloqueado = 1;
    }
    
    modifier noExcederTopeRetiro(uint256 monto) {
        if (monto > topeRetiro) revert TopeRetiroSuperado(monto, topeRetiro);
        _;
    }

    constructor(uint256 _topeBanco, uint256 _topeRetiro) {
        require(_topeBanco > 0 && _topeRetiro > 0, "Limites deben ser > 0");
        dueno = msg.sender;
        topeBanco = _topeBanco;
        topeRetiro = _topeRetiro;
    }

    /// @notice Deposita ETH en la boveda del remitente
    function depositar() public payable {
        if (msg.value == 0) revert DepositoCero();

        unchecked {
            uint256 nuevoTotal = totalGuardado + msg.value;
            if (nuevoTotal > topeBanco) {
                uint256 disponible = topeBanco - totalGuardado;
                revert TopeBancoSuperado(msg.value, disponible);
            }
            totalGuardado = nuevoTotal;
        }

        _aumentarSaldo(msg.sender, msg.value);

        cantidadDepositos++;
        emit Deposito(msg.sender, msg.value);
    }

    /// @notice Retira ETH de la boveda propia, respetando el tope por transaccion
    /// @param monto cantidad en wei a retirar
    function retirar(uint256 monto)
        external
        sinReentrancia
        noExcederTopeRetiro(monto)
    {
        uint256 saldoUsuario = saldos[msg.sender];
        if (monto > saldoUsuario) revert SaldoInsuficiente(saldoUsuario, monto);

        unchecked {
            saldos[msg.sender] = saldoUsuario - monto;
            totalGuardado -= monto;
        }

        (bool exito, ) = msg.sender.call{value: monto}("");
        if (!exito) revert TransferenciaFallida();

        cantidadRetiros++;
        emit Retiro(msg.sender, monto);
    }

    /// @notice Devuelve el saldo guardado de un usuario
    function verSaldo(address usuario) external view returns (uint256) {
        return saldos[usuario];
    }

    function _aumentarSaldo(address usuario, uint256 monto) private {
        saldos[usuario] += monto;
    }

    receive() external payable {
        depositar();
    }

    fallback() external payable {
        depositar();
    }
}

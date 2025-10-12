// lib/features/accounts/models/financial_account.dart

enum AccountType { pagoMovil, transferencia }

class FinancialAccount {
  final int id;
  final AccountType type;
  final String institutionName;
  final String idCard;
  final String? phoneNumber;
  final String? accountNumber;
  final bool isDefault;

  FinancialAccount({
    required this.id,
    required this.type,
    required this.institutionName,
    required this.idCard,
    this.phoneNumber,
    this.accountNumber,
    this.isDefault = false,
  });

  // --- Métodos de Conversión para Sembast ---

  factory FinancialAccount.fromMap(Map<String, dynamic> map, int id) {
    return FinancialAccount(
      id: id, // El ID viene separado en Sembast.
      type: AccountType.values.firstWhere((e) => e.name == map['type']),
      institutionName: map['institutionName'] as String,
      idCard: map['idCard'] as String,
      phoneNumber: map['phoneNumber'] as String?,
      accountNumber: map['accountNumber'] as String?,
      isDefault: map['isDefault'] as bool,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'type': type.name,
      'institutionName': institutionName,
      'idCard': idCard,
      'phoneNumber': phoneNumber,
      'accountNumber': accountNumber,
      'isDefault': isDefault,
    };
  }
  
  // 'copyWith' para actualizar objetos existentes.
  FinancialAccount copyWith({
    int? id,
    AccountType? type,
    String? institutionName,
    String? idCard,
    String? phoneNumber,
    String? accountNumber,
    bool? isDefault,
  }) {
    return FinancialAccount(
      id: id ?? this.id,
      type: type ?? this.type,
      institutionName: institutionName ?? this.institutionName,
      idCard: idCard ?? this.idCard,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      accountNumber: accountNumber ?? this.accountNumber,
      isDefault: isDefault ?? this.isDefault,
    );
  }
}
import 'dart:io';

String verificarPrimo(int num) {
  if (num <= 1) return "Não é primo!"; 

  for (int i = 2; i * i <= num; i++) {
    if (num % i == 0) {
      return "Não é primo!"; 
    }
  }

  return "É primo!"; 
}

void main() {
  String? input = stdin.readLineSync(); 
  if (input != null) {
    if (int.tryParse(input) != null) {
      int num = int.parse(input); 
      if (num < 0) {
        print("Número negativo!");
      } else {
        print(verificarPrimo(num)); 
      }
    } else {
      if (input.isEmpty) {
        print("Entrada vazia!");
      } 
      else if (input.contains(",")) {
        print("Formato numérico inválido!");
      } 
      else if (double.tryParse(input) != null && input.contains(".")) {
        print("Não é inteiro!");
      } 
      else {
        print("Não é um número!");
      }
    }
  }
}
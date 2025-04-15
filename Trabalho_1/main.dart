import 'dart:io';

String verificarPrimo(int num) {
  if (num <= 1) return "Não é primo"; 

  for (int i = 2; i * i <= num; i++) {
    if (num % i == 0) {
      return "Não é primo"; 
    }
  }

  return "É primo"; 
}

void main() {
  print("Digite um número para verificar se é primo:");
  String? input = stdin.readLineSync(); 
  if (input != null) {
    int num = int.parse(input); 
    print(verificarPrimo(num)); 
  }
}
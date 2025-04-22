import 'dart:io';

void main() {
    List<String> input = stdin.readLineSync()!.split(' ');

    if (input.length != 2 || 
        input.any((element) => int.tryParse(element) == null || int.parse(element) < 0)) {
        print('Por favor forneça dois números inteiros positivos.');
        return;
    }

    List<int> limites = input.map(int.parse).toList();
    int inicio = limites[0];
    int fim = limites[1];

    if (inicio > fim) {
        print('O primeiro número deve ser menor ou igual ao segundo.');
        return;
    }

    int maiorNumeroAbundante = 0;
    List<int> fatoresMaiorAbundante = [];
    int somaFatoresMaiorAbundante = 0;

    bool encontrouNumeroPerfeito = false;

    for (int i = inicio; i <= fim; i++) {
        List<int> fatores = obterFatores(i);
        int somaFatores = fatores.isNotEmpty ? fatores.reduce((a, b) => a + b) : 0;

        if (somaFatores == i) {
            encontrouNumeroPerfeito = true;
            print('$i é um número perfeito.');
            print('Fatores: $fatores');
        }

        if (somaFatores > i) {
            if (somaFatores > somaFatoresMaiorAbundante) {
                maiorNumeroAbundante = i;
                fatoresMaiorAbundante = fatores;
                somaFatoresMaiorAbundante = somaFatores;
            }
        }
    }

    if (!encontrouNumeroPerfeito) {
        print('Nenhum número perfeito encontrado na faixa entre $inicio e $fim.');
    }

    if (maiorNumeroAbundante > 0) {
        print('Maior número abundante: $maiorNumeroAbundante');
        print('Fatores: $fatoresMaiorAbundante');
        print('Soma dos fatores: $somaFatoresMaiorAbundante');
    } else {
        print('Nenhum número abundante encontrado na faixa entre $inicio e $fim.');
    }
}

List<int> obterFatores(int numero) {
    List<int> fatores = [];
    for (int i = 1; i <= numero ~/ 2; i++) {
        if (numero % i == 0) {
            fatores.add(i);
        }
    }
    return fatores;
}
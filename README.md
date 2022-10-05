<h1>Trabalho de L.P. - Simulando um Pre-Processador</h1>

Aluno: Gustavo Freitas             
Matéria: Línguagens de Programação                                                    

Objetivo: Implementar um "Pre-Processador" para C que consiga:

- Remover comentários
- Expandir #include e #define
- Remova quebras de linha, espaços e tabulações quando possível

Linguagem: LUA 5.4.4 (Livre Escolha)
https://www.lua.org/

Esse é meu primeiro código em Lua.

<h2>Changelog:</h2>
<b>V2.0:</b>

- Código bem mais simplificado
- Código totalmente comentado
- Muito mais rigor com o conteúdo entre aspas. Coisas como: [printf(" #include <stdio.h> ");] agora são tratadas devidamente
- Agora imprime em [(NomeDoArquivo)-Out.txt] ao invés de imprimir sempre em um mesmo arquivo

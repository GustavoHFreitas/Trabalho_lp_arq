--  _______        _           _ _                   _           _               _____      
-- |__   __|      | |         | | |                 | |         | |             |  __ \     
--    | |_ __ __ _| |__   __ _| | |__   ___       __| | ___     | |             | |__) |    
--    | | '__/ _` | '_ \ / _` | | '_ \ / _ \     / _` |/ _ \    | |             |  ___/     
--    | | | | (_| | |_) | (_| | | | | | (_) |   | (_| |  __/    | |____    _    | |       _ 
--    |_|_|  \__,_|_.__/ \__,_|_|_| |_|\___/     \__,_|\___|    |______|  (_)   |_|      (_)        #V2.0
--                                                                                         
--  Aluno: Gustavo Freitas                                                             Matéria: Línguagens de Programação                                                                   
--  Objetivo: Implementar um "pre-processador" para C que consiga:
--  1 - Remover comentários
--  2 - Expandir #include e #define
--  3 - Remova quebras de linha, espaços e tabulações quando possível
--
--  Linguagem: LUA 5.4.4
--  https://www.lua.org/
--
-- Esse é meu primeiro código em Lua.
--

--(//1!) Funcoes do Codigo (Functions)

--Funcao que escapa de todos os caracteres magicos. (Usando %) (//F1!)
local function MagicEsc(CodigoX)
    CodigoX = CodigoX:gsub('[%-%.%+%[%]%(%)%$%^%%%?%*]','%%%1')
    return CodigoX
end

--Funcao que escapa somente de %, transformando-o em %%        (//F2!)
local function MagicEscSimp(CodigoX)
    CodigoX = CodigoX:gsub('[%%]','%%%1')
    return CodigoX
end

--Funcao para leitura de arquivos (//F3!)
--Obtem um endereco de um arquivo e retorna seu conteudo.
local function LerArq(EnderecoX)                                                               --Obtem um endereco de arquivo
    local Arq = io.open(EnderecoX, "rb")                                                       --Abre o arquivo no endereco
    if not Arq then                                                                            --Caso falhe, termina o programa
        print("Ocorreu um erro ao abrir um arquivo. :(\n")
        print("Certifique-se que o endereco inserido esta correto.")
        print("Nao esqueca de incluir o formato (Ex: main.c);")
        print("Nao esqueca de incluir os arquivos usados no codigo no mesmo diretorio.")
        os.exit()
        return nil 
    end
    local ArqC = Arq:read "*a"                                                                 --Caso contrario, le o arquivo
    Arq:close()                                                                                --Fecha o arquivo
    return ArqC                                                                                --Retorna o conteudo
end

--Funcao que troca os casos de #include " " para < > (//F4!)
--Isso e feito para nao entrar em conflito com a proxima funcao
--Obtem um codigo e retorna o mesmo depois da transformacao
local function IncludeUnify(CodigoX) 
    local PosX,PosY,ValorZ = string.find(CodigoX, [[#include%s+"(%Z-)"]])                      --Procura casos de #include " "
    while PosX ~= nil do                                                                       --Enquanto encontrar
        CodigoX = CodigoX:gsub(string.sub(CodigoX,PosX,PosY), "#include <"..ValorZ..'>')       --Faz a substituicao
        PosX,PosY,ValorZ = string.find(CodigoX, [[#include%s+"(%Z-)"]],PosY+1)                 --Testa para outro caso de onde parou
    end     
    return CodigoX                                                                             --Retorna o codigo
end

--Funcao para insercao do conteudo entre aspas na tabela (//F5!)
--Recebe um codigo e uma tabela, e coloca todos os casos de " " nessa tabela. O intuito e separar todos os casos de " " para que nao sejam afetados pelas outras funcoes.


--Levando em consideracao que \" nao sao aspas validas, primeiro esses casos sao substituidos por quebra de linha, como a quebra de linha nao pode ser usada entre " "
--(A nao ser quando representada por \n) ficara claro posteriormente que ela esta substituindo um \" (1)

--Depois, inclui os casos entre " " na tabela. Como \" foram substituidos nao ha perigo de pegar um caso em falso. (2)

--Finalmente, os casos entre " " sao substituidos no codigo por @X@ onde X e a posicao na tabela, posteriormente, ja no final do codigo
--os @X@ serao substituidos pelos valores originais. (F10 - AspasRep) (3)

--Eu achei que essa forma com substituicao e a de mais facil compreensao, e permitiria uma flexibilidade maior na hora de escrever as outras funcoes, ja que nao precisaria
--me preocupar com conteudo entre aspas que nao deve ser alterado


--Retorna o codigo final e a tabela.
local function AspasSweepM(CodigoX,TabelaX)
    local CodigoAux = CodigoX:gsub([[\"]], "\n")                                            --Gera um codigo onde \" esta substituido por quebra de linha     (1)           
    local PosX,PosY = string.find(CodigoAux, [["(.-)"]])                                    --Procura um caso de " "                                          (2)
    while PosX ~= nil do                                                                    --Enquanto encontrar
        TabelaX[#TabelaX + 1] = string.sub(CodigoAux,PosX,PosY):gsub("\n",[[\"]])           --Adiciona o caso atual na tabela, ja trocando os \n de volta para \"
        CodigoX = CodigoX:gsub(MagicEsc(TabelaX[#TabelaX]),"@"..(#TabelaX).."@")            --Substitui as instancias desse caso no codigo por @X@ (//F1*)    (3)
        PosX,PosY = string.find(CodigoAux, [["(.-)"]],PosY+1)                               --Testa para um proximo caso
    end
    return CodigoX,TabelaX                                                                  --Retorna o codigo e a tabela
end

--Funcao que remove os comentarios do codigo (//F6!)
local function RemoveComentario(CodigoX)
    CodigoX = CodigoX:gsub("//.-\n", '')                                                    --Remove comentarios singulares
    CodigoX = CodigoX:gsub("/%*.-%*/", '')                                                  --Remove comentarios multi-linha
    return CodigoX                                                                          --Retorna o codigo
end

--Funcao que remove espacos, quebras de linha e tabulacoes. (//F7!)
local function RemoveEspacos(CodigoX)
    CodigoX = CodigoX:gsub("[\r\n\v\t]", " ")                                               --Transforma tabulacoes, quebras de linha, etc em um espaco
    CodigoX = CodigoX:gsub("%s%s",' ')                                                      --Singulariza todos os espacos

    --O espaco vai ser desnecessario caso tenha um simbolo entre ele.
    --Ex: (int main / return 1) - Necessario
    --Ex: (5 > 2 ? 10 : 43) - Desnecessario
    local PosX,PosY,ValorW = string.find(CodigoX, "%s(%W)")                                 --Procura casos de Espaco + Simbolo
    while ValorW ~= nil do                                                                  --Se encontrado
        CodigoX = CodigoX:gsub(MagicEsc(string.sub(CodigoX,PosX,PosY)),ValorW)              --Substitui todos esses casos pelo simbolo (Sem espaco)
        PosX,PosY,ValorW = string.find(CodigoX, "%s(%W)",PosX)                              --Testa por outro caso
    end
    PosX,PosY,ValorW = string.find(CodigoX, "(%W)%s")                                       --Procura casos de Simbolo + Espaco
    while PosX ~= nil do                                                                    --Se encontrado
        CodigoX = CodigoX:gsub(MagicEsc(string.sub(CodigoX,PosX,PosY)),ValorW)              --Substitui todos esses casos pelo simbolo (Sem espaco)
        PosX,PosY,ValorW = string.find(CodigoX, "(%W)%s",PosX)                              --Testa por outro caso
    end

    --Ainda pode existir um espaco desnecessario no comeco ou final do codigo
    while string.sub(CodigoX,1,1) == ' ' do                                                 --Testa se o primeiro caractere e um espaco
        CodigoX = string.sub(CodigoX,2)                                                     --Caso seja, pula um caractere
    end

    while string.sub(CodigoX,-1) == ' ' do                                                  --Testa se o ultimo caractere e um espaco
        CodigoX = CodigoX:sub(1,-2)                                                         --Caso seja, diminui um caractere
    end

    return CodigoX                                                                          --Retorna o codigo
end

--Funcao que substitui os define's. (//F8!)
local function DefineRep(CodigoX)
    local PosX,PosY,Valor1,Valor2 = string.find(CodigoX, "#define%s+(%Z-)%s+(%Z-)\n")       --Encontra os casos de define
    while Valor1 ~= nil do                                                                  --Enquanto encontrar
        Valor2 = Valor2:gsub("\r",'')
        local ParteAnterior = string.sub(CodigoX,1,PosX-1)                                  --Divide a string em dois,
        local PartePosterior = string.sub(CodigoX,PosY)                                     --garantindo que o define so substitua somente ocorrencias a frente dele
        PartePosterior = PartePosterior:gsub(Valor1,Valor2)                                 --Faz a substituicao
        CodigoX = ParteAnterior..PartePosterior                                             --Junta as duas partes
        PosX,PosY,Valor1,Valor2 = string.find(CodigoX, "#define%s+(%Z-)%s+(%Z-)\n",PosX+1)  --Testa para um proximo caso
    end
    return CodigoX                                                                          --Retorna o codigo
end 

--Funcao que expande os include's. (//F9!)
local function IncludeRep(CodigoX)
    local PosX,PosY,ValorZ = string.find(CodigoX, "#include%s+<(%Z-)>")                     --Encontra os casos de include
        while ValorZ ~= nil do                                                              --Enquanto encontrar
            ValorZ = LerArq(ValorZ)                                                         --Le o arquivo do include
            CodigoX = CodigoX:gsub(MagicEsc(string.sub(CodigoX,PosX,PosY)),ValorZ)          --Faz a substituicao
            PosX,PosY,ValorZ = string.find(CodigoX, "#include%s+<(%Z-)>",PosY+1)            --Testa para um proximo caso
        end
    return CodigoX                                                                          --Retorna o codigo
end

--Funcao que re-insere as aspas. (//F10!)
local function AspasRep(CodigoX,TabelaX)
    for i, v in pairs(TabelaX) do                                                           --Acessa em ordem os elementos da tabela
        CodigoX = CodigoX:gsub("@"..i.."@",MagicEscSimp(v))                                 --Faz a substituiçao de cada elemento
    end
    return CodigoX                                                                          --Retorna o codigo
end

--(//2!) Inicio do Codigo (Start)

--Obtem o nome/diretorio do arquivo e le o conteudo
print("Insira o nome / diretorio do arquivo (Incluindo o formato):")
print("(Lembre-se de incluir os arquivos dos #include's na mesma pasta.)\n")
local Diretorio = io.read("*l")
local Codigo = LerArq(Diretorio)

--Executa as funcoes
Codigo = IncludeUnify(Codigo)
TabelaAspas = {}
Codigo,TabelaAspas = AspasSweepM(Codigo,TabelaAspas)
Codigo = RemoveComentario(Codigo)
Codigo = DefineRep(Codigo)
Codigo = IncludeRep(Codigo)
Codigo = RemoveEspacos(Codigo)
Codigo = AspasRep(Codigo,TabelaAspas)

--Escreve Codigo em X-Out.txt
Diretorio = Diretorio.."-Out.txt"
local out = io.open(Diretorio, "w")
out:write(Codigo)
print(Codigo)
print("\nArquivo gerado com sucesso.\n")
